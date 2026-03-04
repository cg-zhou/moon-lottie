import { createCanvas, createImageData } from 'canvas';
import { readFileSync, writeFileSync } from 'fs';

const FRAME = 10;
const WIDTH = 1000;
const HEIGHT = 1000;

const animJsonStr = readFileSync('samples/1_4_Cat_Fishing_On_Moon.json', 'utf-8');
const wasmBuffer = readFileSync('_build/wasm-gc/debug/build/cmd/main/main.wasm');

// --- Render with MoonLottie WASM ---
const moonCanvas = createCanvas(WIDTH, HEIGHT);
let ctx = moonCanvas.getContext('2d');
let currentJsonStr = animJsonStr;
let currentGradient = null;
const fillRuleStack = [];
const offscreenStack = [];

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

const importObject = {
  demo: {
    get_json_len: () => currentJsonStr.length,
    get_json_char: (idx) => currentJsonStr.charCodeAt(idx),
    log_frame: (f) => {}
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
    drawImage: (id, w, h) => {},
    drawText: (text, font, size, r, g, b, a, justify) => {},
    setGlobalCompositeOperation: (mode) => { ctx.globalCompositeOperation = moonStringJS(mode); },
    beginLayer: () => {
        const offscreen = createCanvas(WIDTH, HEIGHT);
        const offCtx = offscreen.getContext('2d');
        const t = ctx.getTransform();
        offCtx.setTransform(t.a, t.b, t.c, t.d, t.e, t.f);
        offscreenStack.push({ savedCtx: ctx, offscreen, savedOpacity: ctx.globalAlpha });
        ctx = offCtx;
        ctx.globalAlpha = 1.0;
    },
    endLayer: (mode) => {
        if (offscreenStack.length === 0) return;
        const { savedCtx, offscreen, savedOpacity } = offscreenStack.pop();
        savedCtx.save();
        savedCtx.setTransform(1, 0, 0, 1, 0, 0);
        savedCtx.globalCompositeOperation = moonStringJS(mode);
        savedCtx.globalAlpha = savedOpacity;
        savedCtx.drawImage(offscreen, 0, 0);
        savedCtx.restore();
        ctx = savedCtx;
    }
  },
  expressions: {
    evaluate_double: (code_ptr, time, val) => val,
    evaluate_vec_into: (code_ptr, time, arr) => {}
  }
};

console.log("Instantiating WASM...");
const { instance } = await WebAssembly.instantiate(wasmBuffer, importObject);
const moonLottie = instance.exports;

console.log("Rendering MoonLottie frame 10...");
const player = moonLottie.create_player_from_js();
moonLottie.update_player_with_speed(player, FRAME, 0);

const moonPng = moonCanvas.toBuffer('image/png');
writeFileSync('/tmp/moon_frame10.png', moonPng);
console.log("Saved /tmp/moon_frame10.png");

// Now render the reference using a canvas-based lottie implementation
// Since lottie-web doesn't work well in Node.js, let's use a manual approach
// to render the expected output based on the Lottie JSON spec

// For now, let's analyze what moon-lottie drew - we can examine the pixel data
const moonCtx = moonCanvas.getContext('2d');
const moonData = moonCtx.getImageData(0, 0, WIDTH, HEIGHT);

// Count non-transparent pixels
let nonTransparent = 0;
let pixelsByColor = {};
for (let i = 0; i < moonData.data.length; i += 4) {
    const r = moonData.data[i];
    const g = moonData.data[i+1];
    const b = moonData.data[i+2];
    const a = moonData.data[i+3];
    if (a > 0) {
        nonTransparent++;
        const key = `${r},${g},${b},${a}`;
        pixelsByColor[key] = (pixelsByColor[key] || 0) + 1;
    }
}

console.log(`\nMoonLottie render analysis:`);
console.log(`Non-transparent pixels: ${nonTransparent} / ${WIDTH*HEIGHT} (${(nonTransparent*100/WIDTH/HEIGHT).toFixed(2)}%)`);
console.log(`Unique colors: ${Object.keys(pixelsByColor).length}`);

// Show top colors
const topColors = Object.entries(pixelsByColor).sort((a,b) => b[1]-a[1]).slice(0, 20);
console.log("\nTop colors (R,G,B,A : count):");
for (const [color, count] of topColors) {
    console.log(`  ${color} : ${count}`);
}
console.log("\nMoonLottie PNG saved. Please inspect visually.");
