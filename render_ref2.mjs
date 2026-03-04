import { createCanvas, Image } from 'canvas';
import { readFileSync, writeFileSync } from 'fs';
import vm from 'vm';

const FRAME = 10;
const WIDTH = 1000;
const HEIGHT = 1000;

const animJsonStr = readFileSync('samples/1_4_Cat_Fishing_On_Moon.json', 'utf-8');
const animData = JSON.parse(animJsonStr);

const offCanvas = createCanvas(WIDTH, HEIGHT);
const offCtx = offCanvas.getContext('2d');

function makeCanvas() {
    const c = createCanvas(WIDTH, HEIGHT);
    c.style = {};
    c.addEventListener = () => {};
    c.removeEventListener = () => {};
    c.setAttribute = () => {};
    c.getAttribute = () => null;
    return c;
}

const container = {
    _children: [],
    style: {},
    tagName: 'DIV',
    nodeType: 1,
    getAttribute: () => null,
    setAttribute: () => {},
    removeAttribute: () => {},
    appendChild: function(c) { this._children.push(c); },
    removeChild: function(c) {},
    insertBefore: function(c) { this._children.unshift(c); },
    querySelectorAll: () => [],
    querySelector: () => null,
    getElementsByTagName: () => [],
    getElementsByClassName: () => [],
    getBoundingClientRect: () => ({ top: 0, left: 0, width: WIDTH, height: HEIGHT, bottom: HEIGHT, right: WIDTH, x: 0, y: 0 }),
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => {},
    contains: () => true,
    childNodes: [],
    firstChild: null,
    parentNode: null,
    ownerDocument: null,
    cloneNode: function() { return this; },
    get clientWidth() { return WIDTH; },
    get clientHeight() { return HEIGHT; },
    get offsetWidth() { return WIDTH; },
    get offsetHeight() { return HEIGHT; }
};

const fakeDocument = {
    createElement: (tag) => {
        if (tag === 'canvas') return makeCanvas();
        const el = {
            style: {}, tagName: tag.toUpperCase(), nodeType: 1,
            appendChild: function(c) {}, removeChild: () => {},
            getAttribute: () => null, setAttribute: () => {},
            addEventListener: () => {}, removeEventListener: () => {},
            getElementsByTagName: () => [], getElementsByClassName: () => [],
            querySelectorAll: () => [], querySelector: () => null,
            getBoundingClientRect: container.getBoundingClientRect,
            childNodes: [], firstChild: null, contains: () => true,
            cloneNode: function() { return this; },
            ownerDocument: null, parentNode: null,
        };
        el.ownerDocument = fakeDocument;
        return el;
    },
    createElementNS: (ns, tag) => fakeDocument.createElement(tag),
    createTextNode: () => ({ nodeType: 3, textContent: '' }),
    body: { appendChild: () => {}, style: {} },
    documentElement: { style: {} },
    readyState: 'complete',
    addEventListener: () => {},
    removeEventListener: () => {},
    getElementById: () => container,
    querySelectorAll: () => [],
    querySelector: () => null,
    getElementsByTagName: () => [],
    getElementsByClassName: () => [],
};

container.ownerDocument = fakeDocument;

const lottieCode = readFileSync('node_modules/lottie-web/build/player/lottie.js', 'utf-8');

const sandbox = {
    window: null, // will be set below
    document: fakeDocument,
    navigator: { userAgent: 'Node.js' },
    self: null,
    requestAnimationFrame: (cb) => setTimeout(cb, 0),
    cancelAnimationFrame: (id) => clearTimeout(id),
    setTimeout, setInterval, clearTimeout, clearInterval,
    console,
    HTMLElement: function(){},
    HTMLCanvasElement: function(){},
    Element: function(){},
    SVGElement: function(){},
    Node: { ELEMENT_NODE: 1, TEXT_NODE: 3 },
    Event: function(){},
    CustomEvent: function(name, opts){},
    XMLHttpRequest: function(){ this.open = ()=>{}; this.send = ()=>{}; this.addEventListener = ()=>{}; },
    Image: function(){ this.onload = null; this.onerror = null; this.src = ''; this.addEventListener = ()=>{}; },
    Blob: function(){},
    URL: { createObjectURL: () => '' },
    FontFace: function(){ this.load = () => Promise.resolve(); },
    performance: { now: () => Date.now() },
    OffscreenCanvas: undefined,
    createImageBitmap: undefined,
    location: { href: '', protocol: 'http:' },
    Array, Object, String, Number, Boolean, Date, RegExp, Error, TypeError, JSON, Math, Promise,
    parseInt, parseFloat, isNaN, isFinite, encodeURIComponent, decodeURIComponent,
    undefined: undefined,
    Infinity: Infinity,
    NaN: NaN,
};
sandbox.window = sandbox;
sandbox.self = sandbox;

vm.createContext(sandbox);
vm.runInContext(lottieCode, sandbox);

const lottie = sandbox.lottie;
if (!lottie) {
    console.error("lottie not found in sandbox. Available:", Object.keys(sandbox).filter(k => k.startsWith('lottie')));
    process.exit(1);
}
console.log("lottie-web loaded");

const anim = lottie.loadAnimation({
    container: container,
    renderer: 'canvas',
    loop: false,
    autoplay: false,
    animationData: animData,
    rendererSettings: {
        context: offCtx,
        preserveAspectRatio: 'xMidYMid meet',
        clearCanvas: true
    }
});

let domLoaded = false;
anim.addEventListener('DOMLoaded', () => { domLoaded = true; });

// Wait for DOMLoaded
for (let i = 0; i < 50; i++) {
    await new Promise(r => setTimeout(r, 100));
    if (domLoaded) break;
}

if (!domLoaded) {
    console.log("DOMLoaded never fired, trying anyway...");
}

console.log("Going to frame", FRAME);
anim.goToAndStop(FRAME, true);

const pngBuf = offCanvas.toBuffer('image/png');
writeFileSync('/tmp/official_frame10.png', pngBuf);
console.log("Saved /tmp/official_frame10.png");

// Check non-transparent pixels
const officialData = offCtx.getImageData(0, 0, WIDTH, HEIGHT);
let officialNonTransparent = 0;
for (let i = 0; i < officialData.data.length; i += 4) {
    if (officialData.data[i+3] > 0) officialNonTransparent++;
}
console.log(`Official non-transparent pixels: ${officialNonTransparent}`);

// Compare
const moonImg = new Image();
const moonPngBuf = readFileSync('/tmp/moon_frame10.png');
moonImg.onload = () => {
    const moonCanvas2 = createCanvas(WIDTH, HEIGHT);
    const moonCtx = moonCanvas2.getContext('2d');
    moonCtx.drawImage(moonImg, 0, 0);
    const moonData = moonCtx.getImageData(0, 0, WIDTH, HEIGHT);
    
    let totalDiff = 0, maxDiff = 0, diffPixelCount = 0, significantDiffCount = 0;
    const regionSize = 100;
    const regionDiffs = {};
    
    for (let i = 0; i < moonData.data.length; i += 4) {
        const pixelIdx = i / 4;
        const x = pixelIdx % WIDTH;
        const y = Math.floor(pixelIdx / WIDTH);
        
        const dr = Math.abs(moonData.data[i] - officialData.data[i]);
        const dg = Math.abs(moonData.data[i+1] - officialData.data[i+1]);
        const db = Math.abs(moonData.data[i+2] - officialData.data[i+2]);
        const da = Math.abs(moonData.data[i+3] - officialData.data[i+3]);
        const pixelDiff = dr + dg + db + da;
        
        if (pixelDiff > 0) {
            diffPixelCount++;
            totalDiff += pixelDiff;
            maxDiff = Math.max(maxDiff, pixelDiff);
            if (pixelDiff > 10) {
                significantDiffCount++;
                const rx = Math.floor(x / regionSize);
                const ry = Math.floor(y / regionSize);
                const key = `${rx},${ry}`;
                regionDiffs[key] = (regionDiffs[key] || 0) + 1;
            }
        }
    }
    
    const diffCanvas3 = createCanvas(WIDTH, HEIGHT);
    const diffCtx3 = diffCanvas3.getContext('2d');
    const diffImgData = diffCtx3.createImageData(WIDTH, HEIGHT);
    for (let i = 0; i < moonData.data.length; i += 4) {
        const dr = Math.abs(moonData.data[i] - officialData.data[i]);
        const dg = Math.abs(moonData.data[i+1] - officialData.data[i+1]);
        const db = Math.abs(moonData.data[i+2] - officialData.data[i+2]);
        const amp = 10;
        diffImgData.data[i] = Math.min(255, dr * amp);
        diffImgData.data[i+1] = Math.min(255, dg * amp);
        diffImgData.data[i+2] = Math.min(255, db * amp);
        diffImgData.data[i+3] = 255;
    }
    diffCtx3.putImageData(diffImgData, 0, 0);
    writeFileSync('/tmp/diff_frame10.png', diffCanvas3.toBuffer('image/png'));
    
    const totalPixels = WIDTH * HEIGHT;
    console.log(`\n=== DIFF STATS ===`);
    console.log(`Total pixels: ${totalPixels}`);
    console.log(`Different pixels: ${diffPixelCount} (${(diffPixelCount/totalPixels*100).toFixed(2)}%)`);
    console.log(`Significant diff (>10): ${significantDiffCount} (${(significantDiffCount/totalPixels*100).toFixed(2)}%)`);
    console.log(`Max single-pixel diff: ${maxDiff}`);
    console.log(`Avg diff: ${diffPixelCount > 0 ? (totalDiff/diffPixelCount).toFixed(2) : 0}`);
    
    console.log(`\nTop different regions:`);
    Object.entries(regionDiffs)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 15)
        .forEach(([key, count]) => {
            const [rx, ry] = key.split(',').map(Number);
            console.log(`  (${rx*regionSize}-${(rx+1)*regionSize}, ${ry*regionSize}-${(ry+1)*regionSize}): ${count} px`);
        });
    process.exit(0);
};
moonImg.src = moonPngBuf;
