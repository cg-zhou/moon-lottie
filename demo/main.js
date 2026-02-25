// MoonLottie Driver for WebAssembly GC

const canvas = document.getElementById('lottie-canvas');
const ctx = canvas.getContext('2d');
const statusEl = document.getElementById('status');
const frameInfoEl = document.getElementById('frame-info');
const playPauseBtn = document.getElementById('play-pause');
const seekBar = document.getElementById('seek-bar');
const fileInput = document.getElementById('file-input');

let isPlaying = true;
let currentFrame = 0;
let player = null;
let currentJsonStr = "";
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

let currentGradient = null;

const fillRuleStack = [];

// Canvas FFI
const importObject = {
  demo: {
    get_json_len: () => currentJsonStr.length,
    get_json_char: (idx) => currentJsonStr.charCodeAt(idx),
    log_frame: (f) => {
        if (Math.floor(f) % 30 === 0) console.log("WASM Frame:", f);
    }
  },
  spectest: {
    print_char: (c) => {
        // Optional: Buffer chars till newline for console.log
    }
  },
  canvas: {
    save: () => {
        ctx.save();
        fillRuleStack.push(ctx._currentFillRule || "nonzero");
    },
    restore: () => {
        ctx.restore();
        ctx._currentFillRule = fillRuleStack.pop() || "nonzero";
    },
    beginPath: () => ctx.beginPath(),
    closePath: () => ctx.closePath(),
    moveTo: (x, y) => ctx.moveTo(x, y),
    lineTo: (x, y) => ctx.lineTo(x, y),
    bezierCurveTo: (cp1x, cp1y, cp2x, cp2y, x, y) => ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y),
    fill: (r, g, b, a) => { 
        ctx.save();
        ctx.globalAlpha = a;
        ctx.fillStyle = `rgb(${r},${g},${b})`; 
        ctx.fill(ctx._currentFillRule || "nonzero"); 
        ctx.restore();
    },
    stroke: (r, g, b, a, width) => { 
        ctx.save();
        ctx.globalAlpha = a;
        ctx.strokeStyle = `rgb(${r},${g},${b})`; 
        ctx.lineWidth = width; 
        ctx.stroke(); 
        ctx.restore();
    },
    setStrokeStyle: (cap, join, miter) => {
        const caps = ["butt", "round", "square"];
        const joins = ["miter", "round", "bevel"];
        ctx.lineCap = caps[cap - 1] || "butt";
        ctx.lineJoin = joins[join - 1] || "miter";
        ctx.miterLimit = miter;
    },
    setFillRule: (rule) => {
        // rule is "nonzero" or "evenodd"
        // ctx doesn't have setFillRule, but fill() and clip() take the rule
        // We'll store it on the context for our helpers
        ctx._currentFillRule = moonStringJS(rule);
    },
    createLinearGradient: (x1, y1, x2, y2) => {
        currentGradient = ctx.createLinearGradient(x1, y1, x2, y2);
    },
    createRadialGradient: (cx, cy, r, fx, fy, fr) => {
        // Lottie radial: cx, cy is start (inner), r is radius (outer)
        // Canvas radial: x1, y1, r1, x2, y2, r2
        currentGradient = ctx.createRadialGradient(fx, fy, fr, cx, cy, r);
    },
    addGradientStop: (offset, r, g, b, a) => {
        if (currentGradient) {
            currentGradient.addColorStop(offset, `rgba(${r},${g},${b},${a})`);
        }
    },
    fillGradient: (a) => {
        if (currentGradient) {
            ctx.save();
            ctx.globalAlpha = a;
            ctx.fillStyle = currentGradient;
            ctx.fill(ctx._currentFillRule || "nonzero");
            ctx.restore();
        }
    },
    strokeGradient: (a, w) => {
        if (currentGradient) {
            ctx.save();
            ctx.globalAlpha = a;
            ctx.strokeStyle = currentGradient;
            ctx.lineWidth = w;
            ctx.stroke();
            ctx.restore();
        }
    },
    clip: () => ctx.clip(ctx._currentFillRule || "nonzero"),
    clearRect: (x, y, w, h) => ctx.clearRect(x, y, w, h),
    setGlobalAlpha: (a) => { ctx.globalAlpha = a; },
    setOpacity: (a) => { ctx.globalAlpha *= a; },

    setTransform: (a, b, c, d, e, f) => ctx.setTransform(a, b, c, d, e, f),
    transform: (a, b, c, d, e, f) => ctx.transform(a, b, c, d, e, f),
    drawImage: (id, w, h) => {
        const idStr = moonStringJS(id);
        const img = imageAssets.get(idStr);
        if (img) {
            ctx.drawImage(img, 0, 0, w, h);
        }
    },
    drawText: (text, font, size, r, g, b, a, justify) => {
        const textStr = moonStringJS(text);
        const fontStr = moonStringJS(font);
        ctx.save();
        ctx.globalAlpha = a;
        ctx.fillStyle = `rgb(${r},${g},${b})`;
        ctx.font = `${size}px ${fontStr || 'Arial'}`;
        const aligns = ["left", "right", "center"];
        ctx.textAlign = aligns[justify] || "left";
        ctx.fillText(textStr, 0, 0);
        ctx.restore();
    },
    setGlobalCompositeOperation: (mode) => {
        ctx.globalCompositeOperation = moonStringJS(mode);
    }
  },
  expressions: {
    evaluate_double: (code_ptr, time, val) => {
        const code = moonStringJS(code_ptr);
        try {
            // Lottie expressions can return numbers or assume last expression is return value
            // We wrap it in a function. Lottie expressions often reference 'thisLayer', 'content', etc.
            // For now we only support 'value' and 'time'.
            const fn = new Function('value', 'time', `"use strict"; return (${code});`);
            const res = fn(val, time);
            return typeof res === 'number' ? res : val;
        } catch (e) {
            console.debug("Expression eval failed:", e, code);
            return val;
        }
    },
    evaluate_vec_into: (code_ptr, time, arr) => {
        const code = moonStringJS(code_ptr);
        try {
            const val = [];
            for (let i = 0; i < arr.length; i++) {
                val.push(arr.get(i));
            }
            const fn = new Function('value', 'time', `"use strict"; return (${code});`);
            const res = fn(val, time);
            if (Array.isArray(res)) {
                for (let i = 0; i < Math.min(res.length, arr.length); i++) {
                    arr.set(i, res[i]);
                }
            } else if (typeof res === 'number') {
                arr.set(0, res); // In case it returns single number for vec
            }
        } catch (e) {
            console.debug("Expression eval (vec) failed:", e, code);
        }
    }
  }
};

async function init() {
  try {
    // 指向 MoonBit 默认的构建产物路径
    const wasmPath = '../_build/wasm-gc/debug/build/cmd/main/main.wasm';
    const response = await fetch(wasmPath);
    if (!response.ok) throw new Error(`Failed to load WASM from ${wasmPath}. Please run 'moon build --target wasm-gc' first.`);
    
    const buffer = await response.arrayBuffer();
    const { instance } = await WebAssembly.instantiate(buffer, importObject);
    
    console.log("WASM Exports:", instance.exports);
    window.moonLottie = instance.exports;
    statusEl.innerText = "Ready. Please upload a Lottie JSON.";
    
    // Load sample if exists
    loadSample();
  } catch (err) {
    statusEl.innerText = "Error: " + err.message;
    console.error(err);
  }
}

function loadSample() {
    fetch('assets/sample.json')
        .then(r => {
            if (!r.ok) throw new Error(`HTTP error! status: ${r.status}`);
            return r.json();
        })
        .then(data => {
            startPlayer(JSON.stringify(data));
        })
        .catch(e => {
            console.log("No sample found:", e.message);
            statusEl.innerText = "Ready. Please upload a Lottie JSON.";
        });
}

async function preloadAssets(json) {
    if (!json.assets) return;
    statusEl.innerText = "Loading assets...";
    const promises = json.assets.map(asset => {
        if (asset.p && (asset.p.startsWith('data:') || asset.u !== undefined)) {
            return new Promise((resolve) => {
                const img = new Image();
                img.onload = () => {
                    imageAssets.set(asset.id, img);
                    resolve();
                };
                img.onerror = () => {
                    console.warn("Failed to load image asset:", asset.id);
                    resolve();
                };
                const src = asset.p.startsWith('data:') ? asset.p : (asset.u || '') + asset.p;
                img.src = src;
            });
        }
        return Promise.resolve();
    });
    await Promise.all(promises);
}

async function startPlayer(jsonStr) {
    let animationData;
    try {
        animationData = JSON.parse(jsonStr);
    } catch (e) {
        statusEl.innerText = "Invalid JSON file.";
        return;
    }

    await preloadAssets(animationData);
    
    currentJsonStr = jsonStr;
    
    if (player) {
        player = null; // Reset
    }
    
    // WebAssembly GC exports
    const createFn = window.moonLottie.create_player_from_js;
    const updateFn = window.moonLottie.update_player_with_speed;
    const getFrameCountFn = window.moonLottie.get_frame_count;

    if (!createFn) {
        console.error("Available exports:", Object.keys(window.moonLottie));
        statusEl.innerText = "Error: create_player_from_js export not found.";
        return;
    }

    // Cache functions
    window.currentCreateFn = createFn;
    window.currentUpdateFn = updateFn;
    window.currentGetFrameCountFn = getFrameCountFn;

    try {
        player = createFn();
    } catch (e) {
        console.error("Player creation failed:", e);
        statusEl.innerText = "Error initializing player.";
        return;
    }

    if (!player) {
        statusEl.innerText = "Failed to parse Lottie JSON.";
        return;
    }

    const totalFrames = getFrameCountFn ? getFrameCountFn(player) : 100;
    seekBar.max = totalFrames;
    seekBar.value = 0;

    statusEl.innerText = "Playing animation...";
    currentFrame = 0;
    requestAnimationFrame(renderLoop);
}

function renderLoop() {
    if (!player) return;
    
    if (isPlaying) {
        const speed = parseFloat(document.getElementById('speed').value);
        currentFrame = window.currentUpdateFn(player, currentFrame, speed);
        frameInfoEl.innerText = `Frame: ${Math.floor(currentFrame)}`;
        seekBar.value = currentFrame;

        const totalFrames = window.currentGetFrameCountFn ? window.currentGetFrameCountFn(player) : 1000;
        if (currentFrame >= totalFrames - 1) {
            currentFrame = 0;
        }
    }
    
    requestAnimationFrame(renderLoop);
}

seekBar.oninput = () => {
    if (!player) return;
    currentFrame = parseFloat(seekBar.value);
    window.currentUpdateFn(player, currentFrame, 0); // Update but don't advance
    frameInfoEl.innerText = `Frame: ${Math.floor(currentFrame)}`;
};

playPauseBtn.onclick = () => {
    isPlaying = !isPlaying;
    playPauseBtn.innerText = isPlaying ? "Pause" : "Play";
};

fileInput.onchange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
        startPlayer(event.target.result);
    };
    reader.readAsText(file);
};

init();
