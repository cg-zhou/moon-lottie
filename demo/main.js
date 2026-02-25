// MoonLottie Driver for WebAssembly GC

const canvas = document.getElementById('lottie-canvas');
const ctx = canvas.getContext('2d');
const statusEl = document.getElementById('status');
const frameInfoEl = document.getElementById('frame-info');
const playPauseBtn = document.getElementById('play-pause');
const fileInput = document.getElementById('file-input');

let isPlaying = true;
let currentFrame = 0;
let player = null;
let currentJsonStr = "";

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
    save: () => ctx.save(),
    restore: () => ctx.restore(),
    beginPath: () => ctx.beginPath(),
    closePath: () => ctx.closePath(),
    moveTo: (x, y) => ctx.moveTo(x, y),
    lineTo: (x, y) => ctx.lineTo(x, y),
    bezierCurveTo: (cp1x, cp1y, cp2x, cp2y, x, y) => ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y),
    fill: (r, g, b, a) => { 
        ctx.save();
        ctx.globalAlpha = a;
        ctx.fillStyle = `rgb(${r},${g},${b})`; 
        ctx.fill(); 
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
            ctx.fill();
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
    clip: () => ctx.clip(),
    clearRect: (x, y, w, h) => ctx.clearRect(x, y, w, h),
    setGlobalAlpha: (a) => { ctx.globalAlpha = a; },

    setTransform: (a, b, c, d, e, f) => ctx.setTransform(a, b, c, d, e, f),
    transform: (a, b, c, d, e, f) => ctx.transform(a, b, c, d, e, f),
    drawImage: (id, w, h) => {
        console.log("Draw image:", moonStringJS(id));
    },
    setGlobalCompositeOperation: (mode) => {
        ctx.globalCompositeOperation = moonStringJS(mode);
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

function startPlayer(jsonStr) {
    currentJsonStr = jsonStr;
    
    if (player) {
        player = null; // Reset
    }
    
    // WebAssembly GC exports
    const createFn = window.moonLottie.create_player_from_js;
    const updateFn = window.moonLottie.update_player;

    if (!createFn) {
        console.error("Available exports:", Object.keys(window.moonLottie));
        statusEl.innerText = "Error: create_player_from_js export not found.";
        return;
    }

    // Cache functions
    window.currentCreateFn = createFn;
    window.currentUpdateFn = updateFn;

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
    statusEl.innerText = "Playing animation...";
    currentFrame = 0;
    requestAnimationFrame(renderLoop);
}

function renderLoop() {
    if (!player) return;
    
    if (isPlaying) {
        window.currentUpdateFn(player, currentFrame);
        frameInfoEl.innerText = `Frame: ${Math.floor(currentFrame)}`;
        
        currentFrame += 1.0;
        if (currentFrame > 1000) currentFrame = 0; 
    }
    
    requestAnimationFrame(renderLoop);
}

playPauseBtn.onclick = () => {
    isPlaying = !isPlaying;
    playPauseBtn.innerText = isPlaying ? "Pause" : "Play";
};

fileInput.onchange = (e) => {
    const file = e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
        startPlayer(ev.target.result);
    };
    reader.readAsText(file);
};

init();
