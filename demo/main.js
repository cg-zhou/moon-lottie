// MoonLottie UI 2.0 - 现代化播放驱动

const canvas = document.getElementById('lottie-canvas');
const ctx = canvas.getContext('2d');
const statusDot = document.getElementById('status-dot');
const statusMsg = document.getElementById('status-msg');
const frameInfoEl = document.getElementById('frame-info');
const playPauseBtn = document.getElementById('play-pause');
const seekBar = document.getElementById('seek-bar');
const fileInput = document.getElementById('file-input');
const dropZone = document.getElementById('drop-zone');
const viewport = document.getElementById('viewport');

let isPlaying = true;
let currentFrame = 0;
let lastTimestamp = 0;
let player = null;
let officialPlayer = null;
let currentJsonStr = "";
let currentFileName = "";
let currentFileSize = 0;
let imageAssets = new Map();

// Helper to convert MoonBit string (WasmGC array) to JS string
function moonStringJS(moonStr) {
    if (typeof moonStr === 'string') return moonStr;
    if (!moonStr || typeof moonStr.get !== 'function') return "";
    let res = "";
    for (let i = 0; i < moonStr.length; i++) {
        res += String.fromCharCode(moonStr.get(i));
    }
    return res;
}

// Canvas FFI implementation (省略大部分不变的渲染逻辑，直接进入业务逻辑控制)
let currentGradient = null;
const fillRuleStack = [];

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
        ctx.save(); ctx.globalAlpha = a; ctx.fillStyle = `rgb(${r},${g},${b})`; 
        ctx.fill(ctx._currentFillRule || "nonzero"); ctx.restore();
    },
    stroke: (r, g, b, a, width) => { 
        ctx.save(); ctx.globalAlpha = a; ctx.strokeStyle = `rgb(${r},${g},${b})`; 
        ctx.lineWidth = width; ctx.stroke(); ctx.restore();
    },
    setStrokeStyle: (cap, join, miter) => {
        const caps = ["butt", "round", "square"]; const joins = ["miter", "round", "bevel"];
        ctx.lineCap = caps[cap - 1] || "butt"; ctx.lineJoin = joins[join - 1] || "miter"; ctx.miterLimit = miter;
    },
    setFillRule: (rule) => { ctx._currentFillRule = moonStringJS(rule); },
    createLinearGradient: (x1, y1, x2, y2) => { currentGradient = ctx.createLinearGradient(x1, y1, x2, y2); },
    createRadialGradient: (cx, cy, r, fx, fy, fr) => { currentGradient = ctx.createRadialGradient(fx, fy, fr, cx, cy, r); },
    addGradientStop: (offset, r, g, b, a) => { if (currentGradient) currentGradient.addColorStop(offset, `rgba(${r},${g},${b},${a})`); },
    fillGradient: (a) => { if (currentGradient) { ctx.save(); ctx.globalAlpha = a; ctx.fillStyle = currentGradient; ctx.fill(ctx._currentFillRule || "nonzero"); ctx.restore(); } },
    strokeGradient: (a, w) => { if (currentGradient) { ctx.save(); ctx.globalAlpha = a; ctx.strokeStyle = currentGradient; ctx.lineWidth = w; ctx.stroke(); ctx.restore(); } },
    clip: () => ctx.clip(ctx._currentFillRule || "nonzero"),
    clearRect: (x, y, w, h) => ctx.clearRect(x, y, w, h),
    setGlobalAlpha: (a) => { ctx.globalAlpha = a; },
    setOpacity: (a) => { ctx.globalAlpha *= a; },
    setTransform: (a, b, c, d, e, f) => ctx.setTransform(a, b, c, d, e, f),
    transform: (a, b, c, d, e, f) => ctx.transform(a, b, c, d, e, f),
    drawImage: (id, w, h) => {
        const img = imageAssets.get(moonStringJS(id));
        if (img) ctx.drawImage(img, 0, 0, w, h);
    },
    drawText: (text, font, size, r, g, b, a, justify) => {
        ctx.save(); ctx.globalAlpha = a; ctx.fillStyle = `rgb(${r},${g},${b})`;
        ctx.font = `${size}px ${moonStringJS(font) || 'Arial'}`;
        const aligns = ["left", "right", "center"]; ctx.textAlign = aligns[justify] || "left";
        ctx.fillText(moonStringJS(text), 0, 0); ctx.restore();
    },
    setGlobalCompositeOperation: (mode) => { ctx.globalCompositeOperation = moonStringJS(mode); }
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
    const wasmPath = '../_build/wasm-gc/debug/build/cmd/main/main.wasm';
    const response = await fetch(wasmPath, { cache: 'no-store' });
    if (!response.ok) throw new Error("WASM not found");
    
    const buffer = await response.arrayBuffer();
    const { instance } = await WebAssembly.instantiate(buffer, importObject);
    
    window.moonLottie = instance.exports;
    statusDot.style.background = "#34c759"; // Green
    statusMsg.innerText = "已就绪，请上传 Lottie JSON";
    
    loadSample();
  } catch (err) {
    statusDot.style.background = "#ff3b30"; // Red
    statusMsg.innerText = "错误: " + err.message;
  }
}

function loadSample() {
    loadRemoteAnimation('1-1 Super Mario.json');
}

function loadRemoteAnimation(filename) {
    const path = `../samples/${filename}`;
    
    fetch(path, { cache: 'no-store' }).then(r => {
        currentFileName = filename;
        return r.blob();
    }).then(blob => {
        currentFileSize = blob.size;
        return blob.text();
    }).then(text => {
        startPlayer(text);
    }).catch(e => {
        console.warn(`${filename} not found at ${path}`);
    });
}

async function preloadAssets(json) {
    if (!json.assets) return;
    statusMsg.innerText = "正在加载资源文件...";
    const promises = json.assets.map(asset => {
        if (asset.p) {
            return new Promise((resolve) => {
                const img = new Image();
                img.onload = () => { imageAssets.set(asset.id, img); resolve(); };
                img.onerror = resolve;
                img.src = asset.p.startsWith('data:') ? asset.p : (asset.u || '') + asset.p;
            });
        }
        return Promise.resolve();
    });
    await Promise.all(promises);
}

async function startPlayer(jsonStr) {
    let animationData;
    try { animationData = JSON.parse(jsonStr); } catch (e) { alert("无效的 JSON 文件"); return; }

    statusMsg.innerText = "初始化渲染引擎...";
    await preloadAssets(animationData);
    currentJsonStr = jsonStr;
    
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
    }
    
    officialPlayer = lottie.loadAnimation({
        container: container,
        renderer: 'canvas',
        loop: false,
        autoplay: false,
        animationData: animationData,
        rendererSettings: {
            preserveAspectRatio: 'xMidYMid meet',
            clearCanvas: true
        }
    });

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
    requestAnimationFrame(renderLoop);
}

function renderLoop(timestamp) {
    if (!player) return;
    
    if (isPlaying) {
        if (!lastTimestamp) lastTimestamp = timestamp;
        const deltaTime = (timestamp - lastTimestamp) / 1000;
        lastTimestamp = timestamp;

        const fps = window.moonLottie.get_fps(player);
        const speed = parseFloat(document.getElementById('speed').value);
        
        // 基于真实时间计算应该前进的帧数
        // delta_frames = delta_time(s) * fps * speed
        const frameDelta = deltaTime * fps * speed;
        
        currentFrame = window.moonLottie.update_player_with_speed(player, currentFrame, frameDelta);
        
        const inPoint = window.moonLottie.get_in_point(player);
        const totalFrames = window.moonLottie.get_frame_count(player);
        if (currentFrame >= inPoint + totalFrames) currentFrame = inPoint;

        updateUI();
    } else {
        lastTimestamp = 0;
    }
    
    requestAnimationFrame(renderLoop);
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

// Animation list change
document.getElementById('anim-list').onchange = (e) => {
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

init();
