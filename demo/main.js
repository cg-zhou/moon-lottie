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
let animationData = null;

// Canvas FFI
const importObject = {
  canvas: {
    save: () => ctx.save(),
    restore: () => ctx.restore(),
    beginPath: () => ctx.beginPath(),
    closePath: () => ctx.closePath(),
    moveTo: (x, y) => ctx.moveTo(x, y),
    lineTo: (x, y) => ctx.lineTo(x, y),
    bezierCurveTo: (cp1x, cp1y, cp2x, cp2y, x, y) => ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y),
    fill: (color) => ctx.fill(),
    stroke: (color, width) => ctx.stroke(),
    clearRect: (x, y, w, h) => ctx.clearRect(x, y, w, h),
    setGlobalAlpha: (a) => { ctx.globalAlpha = a; },
    setFillStyle: (c) => { ctx.fillStyle = c; },
    setStrokeStyle: (c) => { ctx.strokeStyle = c; },
    setLineWidth: (w) => { ctx.lineWidth = w; },
    setTransform: (a, b, c, d, e, f) => ctx.setTransform(a, b, c, d, e, f),
    transform: (a, b, c, d, e, f) => ctx.transform(a, b, c, d, e, f),
    drawImage: (id, w, h) => {
        // Image drawing stub - you need to preload images into a Map
        console.log("Draw image:", id);
    }
  },
  spectest: {
    print_char: (c) => {
        // Optional: Buffer chars till newline for console.log
    }
  }
};

async function init() {
  try {
    // Note: Path depends on build output location relative to index.html
    const wasmPath = '../target/wasm-gc/release/build/main/main.wasm';
    const response = await fetch(wasmPath);
    if (!response.ok) throw new Error(`Failed to load WASM from ${wasmPath}`);
    
    const buffer = await response.arrayBuffer();
    const { instance } = await WebAssembly.instantiate(buffer, importObject);
    
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
        .then(r => r.json())
        .then(data => {
            animationData = data;
            startPlayer(JSON.stringify(data));
        })
        .catch(e => console.log("No sample found."));
}

function startPlayer(jsonStr) {
    if (player) {
        // Cleanup old player if needed (MoonBit handles GC)
    }
    player = window.moonLottie.create_player(jsonStr);
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
        window.moonLottie.update_player(player, currentFrame);
        frameInfoEl.innerText = `Frame: ${Math.floor(currentFrame)}`;
        
        currentFrame += 1.0;
        // Basic loop logic: reset if info available (requires more exports)
        // For now, just keep incrementing or user can reset
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
