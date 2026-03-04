// Use jsdom + lottie-web canvas renderer in Node.js
import { createCanvas, createImageData, Image } from 'canvas';
import { readFileSync, writeFileSync } from 'fs';
import { JSDOM } from 'jsdom';

const FRAME = 10;
const WIDTH = 1000;
const HEIGHT = 1000;

const animJsonStr = readFileSync('samples/1_4_Cat_Fishing_On_Moon.json', 'utf-8');
const animData = JSON.parse(animJsonStr);

// Create a jsdom environment
const dom = new JSDOM(`<!DOCTYPE html><html><body><div id="container" style="width:${WIDTH}px;height:${HEIGHT}px"></div></body></html>`, {
    pretendToBeVisual: true,
    resources: 'usable',
    url: 'http://localhost/'
});

const { window } = dom;
const { document } = window;

// Monkey-patch globals that lottie-web expects
global.document = document;
global.window = window;
Object.defineProperty(global, 'navigator', { value: window.navigator, writable: true, configurable: true });
global.HTMLElement = window.HTMLElement;
global.Element = window.Element;
global.Node = window.Node;
global.NodeList = window.NodeList;
global.requestAnimationFrame = (cb) => setTimeout(cb, 0);
global.cancelAnimationFrame = (id) => clearTimeout(id);

// Create a real canvas for lottie-web to draw on
const offCanvas = createCanvas(WIDTH, HEIGHT);
const offCtx = offCanvas.getContext('2d');

// Patch document.createElement to return our canvas when needed
const origCreateElement = document.createElement.bind(document);
document.createElement = function(tag) {
    if (tag === 'canvas') {
        // Return a real canvas object
        const c = createCanvas(WIDTH, HEIGHT);
        c.style = {};
        c.addEventListener = function(){};
        c.removeEventListener = function(){};
        return c;
    }
    return origCreateElement(tag);
};

// Import lottie-web
const lottieScript = readFileSync('node_modules/lottie-web/build/player/lottie.js', 'utf-8');

// Execute lottie-web in the jsdom context  
const scriptEl = document.createElement('script');
scriptEl.textContent = lottieScript;
document.head.appendChild(scriptEl);

// Try to use the global lottie object
const lottie = window.lottie || global.lottie;

if (!lottie) {
    console.log("Failed to load lottie-web. Trying alternative approach...");
    process.exit(1);
}

console.log("lottie-web loaded successfully");

const container = document.getElementById('container');
container.getBoundingClientRect = () => ({ top: 0, left: 0, width: WIDTH, height: HEIGHT, bottom: HEIGHT, right: WIDTH });

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

anim.addEventListener('DOMLoaded', () => {
    console.log("lottie-web DOMLoaded");
    anim.goToAndStop(FRAME, true);
    
    const pngBuf = offCanvas.toBuffer('image/png');
    writeFileSync('/tmp/official_frame10.png', pngBuf);
    console.log("Saved /tmp/official_frame10.png");
    
    // Compare with MoonLottie output
    const moonCanvas2 = createCanvas(WIDTH, HEIGHT);
    const moonCtx = moonCanvas2.getContext('2d');
    const moonPng = readFileSync('/tmp/moon_frame10.png');
    const img = new Image();
    img.onload = () => {
        moonCtx.drawImage(img, 0, 0);
        const moonData = moonCtx.getImageData(0, 0, WIDTH, HEIGHT);
        const officialData = offCtx.getImageData(0, 0, WIDTH, HEIGHT);
        
        // Diff
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
        
        const diffCanvasOut = createCanvas(WIDTH, HEIGHT);
        const diffCtxOut = diffCanvasOut.getContext('2d');
        const diffImageData = diffCtxOut.createImageData(WIDTH, HEIGHT);
        for (let i = 0; i < moonData.data.length; i += 4) {
            const dr = Math.abs(moonData.data[i] - officialData.data[i]);
            const dg = Math.abs(moonData.data[i+1] - officialData.data[i+1]);
            const db = Math.abs(moonData.data[i+2] - officialData.data[i+2]);
            const amp = 10;
            diffImageData.data[i] = Math.min(255, dr * amp);
            diffImageData.data[i+1] = Math.min(255, dg * amp);
            diffImageData.data[i+2] = Math.min(255, db * amp);
            diffImageData.data[i+3] = 255;
        }
        diffCtxOut.putImageData(diffImageData, 0, 0);
        writeFileSync('/tmp/diff_frame10.png', diffCanvasOut.toBuffer('image/png'));
        
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
                console.log(`  Region (${rx*regionSize}-${(rx+1)*regionSize}, ${ry*regionSize}-${(ry+1)*regionSize}): ${count} pixels`);
            });
        
        // Also check official canvas non-transparent pixels
        let officialNonTransparent = 0;
        for (let i = 0; i < officialData.data.length; i += 4) {
            if (officialData.data[i+3] > 0) officialNonTransparent++;
        }
        console.log(`\nOfficial non-transparent pixels: ${officialNonTransparent}`);
        
        process.exit(0);
    };
    img.src = moonPng;
});

setTimeout(() => {
    console.log("Timeout!");
    process.exit(1);
}, 10000);
