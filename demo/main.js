import { collectImageRefsForFrame } from './image_ref_queue.js';

// MoonLottie UI 2.0 - 现代化播放驱动

const canvas = document.getElementById('lottie-canvas');
let ctx = canvas.getContext('2d');
const statusDot = document.getElementById('status-dot');
const statusMsg = document.getElementById('status-msg');
const frameInfoEl = document.getElementById('frame-info');
const playPauseBtn = document.getElementById('play-pause');
const seekBar = document.getElementById('seek-bar');
const fileInput = document.getElementById('file-input');
const dropZone = document.getElementById('drop-zone');
const viewport = document.getElementById('viewport');

const isProd = window.location.hostname !== 'localhost' && window.location.hostname !== '127.0.0.1';

let isPlaying = true;
let currentFrame = 0;
let lastTimestamp = 0;
let player = null;
let officialPlayer = null;
let currentJsonStr = "";
let currentAnimationData = null;
let currentFileName = "";
let currentFileSize = 0;
let imageAssets = new Map();
let imageLayerRefsByFrame = new Map();
let frameImageDrawCursor = 0;
let currentAnimationRequestId = null;

// Helper to convert MoonBit string (WasmGC array) to JS string
function moonStringJS(moonStr) {
    if (typeof moonStr === 'string') return moonStr;
    if (!moonStr) return "";
    const len = typeof moonStr.length === 'function' ? moonStr.length() : moonStr.length;
    if (typeof len !== 'number') return "";
    let res = "";
    for (let i = 0; i < len; i++) {
        const code = typeof moonStr.get === 'function' ? moonStr.get(i) : moonStr[i];
        if (typeof code !== 'number') return "";
        res += String.fromCharCode(code);
    }
    return res;
}

// Canvas FFI implementation (省略大部分不变的渲染逻辑，直接进入业务逻辑控制)
let currentGradient = null;
let currentDash = [];
const fillRuleStack = [];
const offscreenStack = [];
// Stack for two-buffer track matte compositing (lottie-web prepareLayer/exitLayer pattern)
const matteStack = [];

const importObject = {
  demo: {
    get_json_len: () => currentJsonStr.length,
    get_json_char: (idx) => currentJsonStr.charCodeAt(idx),
    log_frame: (f) => {
        // if (Math.floor(f) % 30 === 0) console.log("WASM Frame:", f);
    }
  },
  spectest: { print_char: (c) => {} },
  canvas: {
    save: () => { ctx.save(); fillRuleStack.push(ctx._currentFillRule || "nonzero"); },
    restore: () => { ctx.restore(); ctx._currentFillRule = fillRuleStack.pop() || "nonzero"; },
    beginPath: () => ctx.beginPath(),
    closePath: () => ctx.closePath(),
    moveTo: (x, y) => ctx.moveTo(x, y),
    lineTo: (x, y) => ctx.lineTo(x, y),
    bezierCurveTo: (cp1x, cp1y, cp2x, cp2y, x, y) => ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y),
    fill: (r, g, b, a) => { 
        ctx.save(); ctx.globalAlpha *= a; ctx.fillStyle = `rgb(${r},${g},${b})`; 
        ctx.fill(ctx._currentFillRule || "nonzero"); ctx.restore();
    },
    stroke: (r, g, b, a, width) => { 
        ctx.save(); ctx.globalAlpha *= a; ctx.strokeStyle = `rgb(${r},${g},${b})`; 
        ctx.lineWidth = width; ctx.stroke(); ctx.restore();
    },
    setStrokeStyle: (cap, join, miter) => {
        const caps = ["butt", "round", "square"]; const joins = ["miter", "round", "bevel"];
        ctx.lineCap = caps[cap - 1] || "butt"; ctx.lineJoin = joins[join - 1] || "miter"; ctx.miterLimit = miter;
    },
    beginDash: () => { currentDash = []; },
    addDash: (value) => { currentDash.push(value); },
    applyDash: (offset) => { ctx.setLineDash(currentDash); ctx.lineDashOffset = offset; },
    setFillRule: (rule) => { ctx._currentFillRule = moonStringJS(rule); },
    createLinearGradient: (x1, y1, x2, y2) => { currentGradient = ctx.createLinearGradient(x1, y1, x2, y2); },
    createRadialGradient: (cx, cy, r, fx, fy, fr) => { currentGradient = ctx.createRadialGradient(fx, fy, fr, cx, cy, r); },
    addGradientStop: (offset, r, g, b, a) => { if (currentGradient) currentGradient.addColorStop(offset, `rgba(${r},${g},${b},${a})`); },
    fillGradient: (a) => { if (currentGradient) { ctx.save(); ctx.globalAlpha *= a; ctx.fillStyle = currentGradient; ctx.fill(ctx._currentFillRule || "nonzero"); ctx.restore(); } },
    strokeGradient: (a, w) => { if (currentGradient) { ctx.save(); ctx.globalAlpha *= a; ctx.strokeStyle = currentGradient; ctx.lineWidth = w; ctx.stroke(); ctx.restore(); } },
    clip: () => ctx.clip(ctx._currentFillRule || "nonzero"),
    clearRect: (x, y, w, h) => ctx.clearRect(x, y, w, h),
    setGlobalAlpha: (a) => { ctx.globalAlpha = a; },
    setOpacity: (a) => { ctx.globalAlpha *= a; },
    setTransform: (a, b, c, d, e, f) => ctx.setTransform(a, b, c, d, e, f),
    transform: (a, b, c, d, e, f) => ctx.transform(a, b, c, d, e, f),
    drawImage: (id, w, h) => {
        const key = moonStringJS(id);
        let img = imageAssets.get(key);
        if (!img) {
            const refs = getImageRefsForFrame(currentFrame);
            if (refs.length > 0) {
                const idx = frameImageDrawCursor < refs.length ? frameImageDrawCursor : refs.length - 1;
                img = imageAssets.get(refs[idx]);
                frameImageDrawCursor += 1;
            }
        }
        if (img) ctx.drawImage(img, 0, 0, w, h);
    },
    drawText: (text, font, size, r, g, b, a, justify) => {
        ctx.save(); ctx.globalAlpha = a; ctx.fillStyle = `rgb(${r},${g},${b})`;
        ctx.font = `${size}px ${moonStringJS(font) || 'Arial'}`;
        const aligns = ["left", "right", "center"]; ctx.textAlign = aligns[justify] || "left";
        ctx.fillText(moonStringJS(text), 0, 0); ctx.restore();
    },
    setGlobalCompositeOperation: (mode) => {
        const modeStr = moonStringJS(mode);
        // Alpha matte (tt=1) fix: match lottie-web's buffer approach exactly.
        // lottie-web saves layer content to buffer1, clears the canvas, renders the matte
        // with source-over, then applies source-in with buffer1 so that ALL canvas pixels
        // are zeroed outside the matte region.  A plain destination-in drawImage only
        // affects pixels within the drawn primitive's bounding box – everything else
        // would bleed through unchanged, causing the dark-Bg-fills-canvas bug.
        //
        // The guard `offscreenStack.length > 0` ensures this only applies inside an
        // isolated layer (beginLayer context).  Alpha mattes in moon-lottie always
        // trigger beginLayer for the matted layer, so this guard is always satisfied.
        // matteContent is stored on the current offscreen stack entry so that nested
        // layers (e.g. a matte source with its own fill effect) do not accidentally
        // consume each other's saved buffers.
        if (modeStr === 'destination-in' && offscreenStack.length > 0) {
            const entry = offscreenStack[offscreenStack.length - 1];
            const w = ctx.canvas.width;
            const h = ctx.canvas.height;
            // Step 1: snapshot the current layer content at identity pixel coordinates.
            const contentBuffer = document.createElement('canvas');
            contentBuffer.width = w;
            contentBuffer.height = h;
            contentBuffer.getContext('2d').drawImage(ctx.canvas, 0, 0);
            // Step 2: clear the offscreen so the matte renders onto a blank surface.
            ctx.save();
            ctx.setTransform(1, 0, 0, 1, 0, 0);
            ctx.clearRect(0, 0, w, h);
            ctx.restore();
            entry.matteContent = contentBuffer;
            // Leave globalCompositeOperation as source-over so the matte draws normally.
        } else if (modeStr === 'source-over' && offscreenStack.length > 0 &&
                   offscreenStack[offscreenStack.length - 1].matteContent !== null) {
            // The matte has just been rendered onto the cleared offscreen with source-over.
            // Apply lottie-web's source-in step: draw the saved layer content through the
            // matte.  Because the saved buffer is full-canvas size, source-in processes
            // every pixel – zeroing anything outside the matte region.
            const entry = offscreenStack[offscreenStack.length - 1];
            const buf = entry.matteContent;
            entry.matteContent = null;
            ctx.save();
            ctx.setTransform(1, 0, 0, 1, 0, 0);
            ctx.globalCompositeOperation = 'source-in';
            ctx.drawImage(buf, 0, 0);
            ctx.restore();
            // restore() returns the transform to what it was just before this save().
            // globalCompositeOperation is also restored to its pre-save value (source-over,
            // since we did not change it between clearing the offscreen and now).
        } else {
            ctx.globalCompositeOperation = modeStr;
        }
    },
    beginLayer: () => {
        // Create an offscreen canvas for isolated compositing (track matte support).
        // We copy the current accumulated transform so drawing coordinates are unchanged.
        // matteContent holds the saved layer pixels during the destination-in matte phase
        // (see setGlobalCompositeOperation); it is null when no matte phase is active.
        const offscreen = document.createElement('canvas');
        offscreen.width = canvas.width;
        offscreen.height = canvas.height;
        const offCtx = offscreen.getContext('2d');
        const t = ctx.getTransform();
        offCtx.setTransform(t.a, t.b, t.c, t.d, t.e, t.f);
        offscreenStack.push({ savedCtx: ctx, offscreen, savedOpacity: ctx.globalAlpha, matteContent: null });
        ctx = offCtx;
        ctx.globalAlpha = 1.0;
    },
    endLayer: (mode) => {
        if (offscreenStack.length === 0) return;
        const { savedCtx, offscreen, savedOpacity } = offscreenStack.pop();
        // Composite the offscreen layer onto the main canvas using identity transform.
        savedCtx.save();
        savedCtx.setTransform(1, 0, 0, 1, 0, 0);
        savedCtx.globalCompositeOperation = moonStringJS(mode);
        savedCtx.globalAlpha = savedOpacity;
        savedCtx.drawImage(offscreen, 0, 0);
        savedCtx.restore();
        ctx = savedCtx;
    },
    // Two-buffer track matte compositing (lottie-web prepareLayer/exitLayer pattern).
    // Called before save() and layer transforms: saves background to buffer[0],
    // captures currentTransform, clears canvas.
    prepareMatteLayer: () => {
        const buf0 = document.createElement('canvas');
        buf0.width = canvas.width;
        buf0.height = canvas.height;
        const buf0Ctx = buf0.getContext('2d');
        buf0Ctx.drawImage(canvas, 0, 0);
        const currentTransform = ctx.getTransform();
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.setTransform(currentTransform);
        matteStack.push({ buf0, buf1: null, currentTransform });
    },
    // Called after restore(): saves layer content to buffer[1],
    // clears canvas, restores base transform for matte source rendering.
    beginMatteExit: () => {
        if (matteStack.length === 0) return;
        const state = matteStack[matteStack.length - 1];
        const buf1 = document.createElement('canvas');
        buf1.width = canvas.width;
        buf1.height = canvas.height;
        const buf1Ctx = buf1.getContext('2d');
        buf1Ctx.drawImage(canvas, 0, 0);
        state.buf1 = buf1;
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.setTransform(state.currentTransform);
    },
    // Called after matte source has been rendered on canvas.
    // Composites: source-in(layer content, matte), destination-over(background), restore.
    endMatteExit: (matte_type) => {
        if (matteStack.length === 0) return;
        const { buf0, buf1, currentTransform } = matteStack.pop();
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        // operationsMap: 1=source-in, 2=source-out, 3=source-in, 4=source-out
        const compositeOp = (matte_type === 1 || matte_type === 3) ? 'source-in' : 'source-out';
        ctx.globalCompositeOperation = compositeOp;
        ctx.drawImage(buf1, 0, 0);
        ctx.globalCompositeOperation = 'destination-over';
        ctx.drawImage(buf0, 0, 0);
        ctx.setTransform(currentTransform);
        ctx.globalCompositeOperation = 'source-over';
    }
  },
  expressions: {
    evaluate_double: (code_ptr, time, val) => {
        try { return new Function('value', 'time', `"use strict"; return (${moonStringJS(code_ptr)});`)(val, time); } catch (e) { return val; }
    },
    evaluate_vec_into: (code_ptr, time, arr) => {
        try {
            const res = new Function('value', 'time', `"use strict"; return (${moonStringJS(code_ptr)});`)([...arr], time);
            if (Array.isArray(res)) res.forEach((v, i) => i < arr.length && arr.set(i, v));
        } catch (e) {}
    }
  }
};

async function init() {
  try {
    const wasmPath = isProd ? 'main.wasm' : '../_build/wasm-gc/debug/build/cmd/main/main.wasm';
    const response = await fetch(wasmPath, { cache: 'no-store' });
    if (!response.ok) throw new Error("WASM not found");
    
    const buffer = await response.arrayBuffer();
    const { instance } = await WebAssembly.instantiate(buffer, importObject);
    
    window.moonLottie = instance.exports;
    statusDot.style.background = "#34c759"; // Green
    statusMsg.innerText = "已就绪，请上传 Lottie JSON";
    
    // 动态加载动画列表
    await initAnimList();
  } catch (err) {
    statusDot.style.background = "#ff3b30"; // Red
    statusMsg.innerText = "错误: " + err.message;
  }
}

async function initAnimList() {
    const listEl = document.getElementById('anim-list');
    try {
        const response = await fetch('sample_index.json');
        
        let entries = [];
        if (response.ok) {
            entries = await response.json();
        } else {
            console.warn("sample_index.json not found, using default fallback");
            entries = [{ file: '1-1 Super Mario.json', label: '1-1 Super Mario' }];
        }
        
        listEl.innerHTML = '';
        entries.forEach(entry => {
            const file = typeof entry === 'object' ? entry.file : entry;
            const label = (typeof entry === 'object' ? (entry.label || entry.file) : entry).replace(/\.json$/i, '');
            
            const opt = document.createElement('option');
            opt.value = file;
            opt.innerText = label;
            listEl.appendChild(opt);
        });
        
        const lastSelected = localStorage.getItem('moon-lottie-last-anim');
        const hasLastInList = lastSelected && entries.some(e => (typeof e === 'object' ? e.file : e) === lastSelected);
        
        if (hasLastInList) {
            listEl.value = lastSelected;
            loadRemoteAnimation(lastSelected);
        } else if (entries.length > 0) {
            const firstFile = typeof entries[0] === 'object' ? entries[0].file : entries[0];
            loadRemoteAnimation(firstFile);
        }
    } catch (e) {
        console.error("Failed to initialize animation list:", e);
        // Minimal fallback to ensure something is loaded
        loadSample();
    }
}

function loadSample() {
    loadRemoteAnimation('1_1_Super_Mario.json');
}

function loadRemoteAnimation(filename) {
    // Encode filename to handle spaces and special characters correctly in URLs
    const encodedName = encodeURIComponent(filename);
    const path = isProd ? `samples/${encodedName}` : `../samples/${encodedName}`;
    
    fetch(path, { cache: 'no-store' }).then(r => {
        if (!r.ok) throw new Error(`HTTP error! status: ${r.status}`);
        currentFileName = filename;
        return r.blob();
    }).then(blob => {
        currentFileSize = blob.size;
        return blob.text();
    }).then(text => {
        startPlayer(text);
    }).catch(e => {
        console.warn(`Failed to load ${filename} from ${path}:`, e.message);
    });
}

function resolveAssetSrc(asset) {
    const p = asset.p || '';
    const u = asset.u || '';
    return p === '' ? asset.id : (u + p);
}

async function preloadAssets(json) {
    if (!json.assets) return;
    statusMsg.innerText = "正在加载资源文件...";
    const promises = json.assets.map(asset => {
        if (asset.p) {
            return new Promise((resolve) => {
                const img = new Image();
                img.onload = () => {
                    // Keep both keys for compatibility:
                    // - asset.id: backward compatibility with old runtimes
                    // - resolved src: current runtime path (lottie-rs-aligned)
                    imageAssets.set(asset.id, img);
                    imageAssets.set(resolveAssetSrc(asset), img);
                    resolve();
                };
                img.onerror = resolve;
                img.src = resolveAssetSrc(asset);
            });
        }
        return Promise.resolve();
    });
    await Promise.all(promises);
}

function rebuildImageLayerTimeline(json) {
    imageLayerRefsByFrame = new Map();
    if (!json.layers) return;
    const start = Math.floor(Number(json.ip ?? 0));
    const end = Math.floor(Number(json.op ?? start));
    for (let f = start; f < end; f += 1) {
        imageLayerRefsByFrame.set(f, collectImageRefsForFrame(json, f));
    }
}

function getImageRefsForFrame(frame) {
    const wholeFrame = Math.floor(frame);
    let refs = imageLayerRefsByFrame.get(wholeFrame);
    if (!refs) {
        if (currentAnimationData) {
            refs = collectImageRefsForFrame(currentAnimationData, wholeFrame);
        } else {
            refs = [];
        }
        imageLayerRefsByFrame.set(wholeFrame, refs);
    }
    return refs;
}

async function startPlayer(jsonStr) {
    let animationData;
    try { animationData = JSON.parse(jsonStr); } catch (e) { alert("无效的 JSON 文件"); return; }
    currentAnimationData = animationData;

    console.log(`[MoonLottie] Starting new animation: ${currentFileName}`);
    statusMsg.innerText = "初始化渲染引擎...";
    
    // Stop any existing render loop and reset timing
    if (currentAnimationRequestId) {
        console.log(`[MoonLottie] Cancelling existing animation loop (ID: ${currentAnimationRequestId})`);
        cancelAnimationFrame(currentAnimationRequestId);
        currentAnimationRequestId = null;
    }
    lastTimestamp = 0; 

    await preloadAssets(animationData);
    rebuildImageLayerTimeline(animationData);
    // For embedded image assets, pass id-only metadata to Wasm to avoid copying huge base64 strings.
    // The actual image data has already been preloaded into imageAssets by JS.
    const wasmAnimationData = JSON.parse(JSON.stringify(animationData));
    if (wasmAnimationData.assets) {
        wasmAnimationData.assets.forEach(asset => {
            if (asset && asset.e === 1 && typeof asset.p === 'string' && asset.p.startsWith('data:')) {
                asset.p = '';
            }
        });
    }
    currentJsonStr = JSON.stringify(wasmAnimationData);
    
    const { create_player_from_js, update_player_with_speed, get_frame_count, get_width, get_height, get_fps, get_version } = window.moonLottie;
    
    player = create_player_from_js();
    if (!player) { statusMsg.innerText = "动画解析失败"; return; }

    // Official Player Init (if exists)
    // Update Canvas & Container Styles
    const w = get_width(player);
    const h = get_height(player);
    const aspectRatio = `${w} / ${h}`;

    // Wasm Canvas
    canvas.width = w;
    canvas.height = h;
    canvas.style.aspectRatio = aspectRatio;

    // Official Lottie
    const container = document.getElementById('official-lottie-container');
    container.style.aspectRatio = aspectRatio;
    
    if (officialPlayer) {
        officialPlayer.destroy();
        officialPlayer = null;
    }
    
    const compareEnabled = document.getElementById('compare-toggle').checked;
    if (compareEnabled && window.lottie && typeof window.lottie.loadAnimation === 'function') {
        try {
            officialPlayer = window.lottie.loadAnimation({
                container: container,
                renderer: 'svg',
                loop: false,
                autoplay: false,
                animationData: animationData,
                rendererSettings: {
                    preserveAspectRatio: 'xMidYMid meet',
                    clearCanvas: true
                }
            });
        } catch (e) {
            console.warn("Official renderer init failed:", e);
            officialPlayer = null;
        }
    }

    // Update File & Metadata
    document.getElementById('info-filename').innerText = currentFileName || "未知";
    document.getElementById('info-filesize').innerText = (currentFileSize / 1024).toFixed(2) + " KB";
    document.getElementById('info-size').innerText = `${w} x ${h}`;
    
    const fps = get_fps(player);
    document.getElementById('info-fps').innerText = fps.toFixed(2) + " fps";
    const totalFrames = get_frame_count(player);
    document.getElementById('info-total-frames').innerText = Math.floor(totalFrames);
    document.getElementById('info-duration').innerText = (totalFrames / fps).toFixed(2) + "s";
    document.getElementById('info-version').innerText = moonStringJS(get_version(player));

    const inPoint = window.moonLottie.get_in_point(player);
    seekBar.min = inPoint;
    seekBar.max = inPoint + totalFrames;
    seekBar.value = inPoint;
    currentFrame = inPoint;
    isPlaying = true;
    lastTimestamp = performance.now();
    updatePlayPauseButton();
    
    statusMsg.innerText = "正在播放: " + (animationData.nm || "未命名动画");
    
    currentAnimationRequestId = requestAnimationFrame(renderLoop);
    console.log(`[MoonLottie] New animation loop started (ID: ${currentAnimationRequestId})`);
}

function renderLoop(timestamp) {
    if (!player) return;
    
    if (isPlaying) {
        if (!lastTimestamp) {
            console.log(`[MoonLottie] Render loop iteration starting with new timestamp: ${timestamp}`);
            lastTimestamp = timestamp;
        }
        const deltaTime = (timestamp - lastTimestamp) / 1000;
        lastTimestamp = timestamp;

        const fps = window.moonLottie.get_fps(player);
        const speed = parseFloat(document.getElementById('speed').value);
        
        // 基于真实时间计算应该前进的帧数
        // delta_frames = delta_time(s) * fps * speed
        const frameDelta = deltaTime * fps * speed;
        frameImageDrawCursor = 0;
        
        currentFrame = window.moonLottie.update_player_with_speed(player, currentFrame, frameDelta);
        
        const inPoint = window.moonLottie.get_in_point(player);
        const totalFrames = window.moonLottie.get_frame_count(player);
        if (currentFrame >= inPoint + totalFrames) currentFrame = inPoint;

        updateUI();
    } else {
        lastTimestamp = 0;
    }
    
    currentAnimationRequestId = requestAnimationFrame(renderLoop);
}

function updateUI() {
    const inPoint = window.moonLottie.get_in_point(player);
    const totalFrames = window.moonLottie.get_frame_count(player);
    const relativeFrame = currentFrame - inPoint;
    frameInfoEl.innerText = `${Math.floor(relativeFrame)} / ${Math.floor(totalFrames)}`;
    seekBar.value = currentFrame;

    if (officialPlayer) {
        officialPlayer.goToAndStop(currentFrame, true);
    }
}

function updatePlayPauseButton() {
    playPauseBtn.innerText = isPlaying ? "‖" : "▶";
}

// UI Event Handlers
seekBar.oninput = () => {
    if (!player) return;
    currentFrame = parseFloat(seekBar.value);
    frameImageDrawCursor = 0;
    window.moonLottie.update_player_with_speed(player, currentFrame, 0);
    updateUI();
};

playPauseBtn.onclick = () => {
    isPlaying = !isPlaying;
    updatePlayPauseButton();
};

window.addEventListener('keydown', (e) => {
    if (e.code === 'Space') {
        isPlaying = !isPlaying;
        updatePlayPauseButton();
        e.preventDefault();
    }
});

document.getElementById('speed').oninput = (e) => {
    document.getElementById('speed-val').innerText = e.target.value;
};

// Bg Switcher
document.querySelectorAll('.bg-btn').forEach(btn => {
    btn.onclick = () => {
        document.querySelectorAll('.bg-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const bg = btn.dataset.bg;
        viewport.className = 'viewport-container' + (bg !== 'grid' ? ' bg-' + bg : '') + (document.getElementById('compare-toggle').checked ? ' comparison-mode' : '');
    };
});

// Comparison Toggle
document.getElementById('compare-toggle').onchange = (e) => {
    const isCompare = e.target.checked;
    document.getElementById('official-wrapper').style.display = isCompare ? 'flex' : 'none';
    viewport.classList.toggle('comparison-mode', isCompare);
    if (isCompare) updateUI();
};

function initDeployTime() {
    const deployTimeEl = document.getElementById('deploy-time');
    if (deployTimeEl && deployTimeEl.dataset.utc) {
        const utcStr = deployTimeEl.dataset.utc;
        const date = new Date(utcStr);
        if (!isNaN(date.getTime())) {
            deployTimeEl.innerText = date.toLocaleString();
            deployTimeEl.title = `UTC: ${utcStr}`;
        }
    }
}

// Animation list change
document.getElementById('anim-list').onchange = (e) => {
    localStorage.setItem('moon-lottie-last-anim', e.target.value);
    loadRemoteAnimation(e.target.value);
};

// Drag & Drop
dropZone.onclick = () => fileInput.click();
fileInput.onchange = (e) => {
    const file = e.target.files[0];
    if (file) handleFile(file);
};

dropZone.ondragover = (e) => { e.preventDefault(); dropZone.classList.add('dragover'); };
dropZone.ondragleave = () => dropZone.classList.remove('dragover');
dropZone.ondrop = (e) => {
    e.preventDefault();
    dropZone.classList.remove('dragover');
    const file = e.dataTransfer.files[0];
    if (file) handleFile(file);
};

function handleFile(file) {
    currentFileName = file.name;
    currentFileSize = file.size;
    const reader = new FileReader();
    reader.onload = (e) => startPlayer(e.target.result);
    reader.readAsText(file);
}

init().then(() => {
    initDeployTime();
});
