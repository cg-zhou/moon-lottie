const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

const dom = new JSDOM('<!DOCTYPE html><html><body><div id="container"></div></body></html>', { pretendToBeVisual: true });
global.window = dom.window;
global.document = dom.window.document;
global.navigator = dom.window.navigator;
global.Node = dom.window.Node;
global.Element = dom.window.Element;
global.HTMLDivElement = dom.window.HTMLDivElement;

dom.window.HTMLCanvasElement.prototype.getContext = function() {
    return { fillRect:()=>{}, clearRect:()=>{}, getImageData:(x,y,w,h)=>({data:new Uint8ClampedArray(w*h*4)}), 
             putImageData:()=>{}, createImageData:()=>([]), setTransform:()=>{}, drawImage:()=>{},
             save:()=>{}, restore:()=>{}, beginPath:()=>{}, moveTo:()=>{}, lineTo:()=>{}, closePath:()=>{},
             stroke:()=>{}, translate:()=>{}, scale:()=>{}, rotate:()=>{}, arc:()=>{}, fill:()=>{},
             measureText:()=>({width:0}), transform:()=>{}, rect:()=>{}, clip:()=>{} };
};

const lottie = require('lottie-web');
const animData = JSON.parse(fs.readFileSync(path.join(__dirname, '../../samples/2_3_banner.json'), 'utf8'));
const container = document.getElementById('container');

const anim = lottie.loadAnimation({
    container, renderer: 'svg', loop: false, autoplay: false, animationData: animData,
});

anim.addEventListener('DOMLoaded', () => {
    const frames = [70, 71, 75, 77, 80, 85, 90, 100, 110, 120, 130, 140, 150];
    const results = {};
    
    for (const frame of frames) {
        anim.goToAndStop(frame, true);
        const svg = container.querySelector('svg').outerHTML;
        
        // Find the bg_avion group transform
        const match = svg.match(/transform="matrix\(1,0,0,1,0,(-[\d.]+)\)"/);
        if (match) {
            results[frame] = parseFloat(match[1]);
        }
    }
    
    console.log('Frame → transform_y:');
    for (const [f, y] of Object.entries(results)) {
        console.log(`  frame ${f}: transform_y = ${y}`);
    }
    
    anim.destroy();
    process.exit(0);
});
