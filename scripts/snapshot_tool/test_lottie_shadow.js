const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

// Setup JSDOM environment for lottie-web
const dom = new JSDOM('<!DOCTYPE html><html><body><div id="container"></div></body></html>', {
    pretendToBeVisual: true
});
global.window = dom.window;
global.document = dom.window.document;
global.navigator = dom.window.navigator;
global.Node = dom.window.Node;
global.Element = dom.window.Element;
global.HTMLDivElement = dom.window.HTMLDivElement;

// Mock Canvas
dom.window.HTMLCanvasElement.prototype.getContext = function() {
    return { fillRect: () => {}, clearRect: () => {}, getImageData: (x, y, w, h) => ({ data: new Uint8ClampedArray(w * h * 4) }), putImageData: () => {}, createImageData: () => ([]), setTransform: () => {}, drawImage: () => {}, save: () => {}, restore: () => {}, beginPath: () => {}, moveTo: () => {}, lineTo: () => {}, closePath: () => {}, stroke: () => {}, translate: () => {}, scale: () => {}, rotate: () => {}, arc: () => {}, fill: () => {}, measureText: () => ({ width: 0 }), transform: () => {}, rect: () => {}, clip: () => {} };
};

const lottie = require('/home/runner/work/moon-lottie/moon-lottie/scripts/snapshot_tool/node_modules/lottie-web');

const filePath = '/home/runner/work/moon-lottie/moon-lottie/samples/2_1_adrock.json';
const animationData = JSON.parse(fs.readFileSync(filePath, 'utf8'));

const container = document.getElementById('container');
const anim = lottie.loadAnimation({
    container: container,
    renderer: 'svg',
    loop: false,
    autoplay: false,
    animationData: animationData,
});

anim.addEventListener('DOMLoaded', () => {
    // Go to frame 5
    anim.goToAndStop(5, true);
    
    const svgElement = container.querySelector('svg');
    const svgContent = svgElement ? svgElement.outerHTML : 'no svg';
    
    // Look for sombra elements in the SVG
    const allElements = container.querySelectorAll('[class*="sombra"], [id*="sombra"]');
    console.log('Sombra elements count:', allElements.length);
    
    // Look for elements with specific paths that match sombra layers
    // The sombra layers are layers 11 and 12 (ind=11, ind=12)
    // In lottie-web SVG, layers get specific ids
    const allGs = container.querySelectorAll('g');
    let sombraGs = [];
    allGs.forEach(g => {
        const textContent = g.innerHTML;
        if (textContent.includes('226.199') || textContent.includes('246.234') || 
            textContent.includes('242.152') || textContent.includes('53.95')) {
            sombraGs.push(g.outerHTML.substring(0, 200));
        }
    });
    console.log('Sombra-related elements:', sombraGs.slice(0, 3));
    
    // Print the full SVG to find sombra layers
    const layerGsAll = container.querySelectorAll('g[id]');
    layerGsAll.forEach(g => {
        const id = g.getAttribute('id');
        const cls = g.getAttribute('class');
        if (id || cls) {
            console.log('G id=' + id + ' class=' + cls + ' innerHTML.length=' + g.innerHTML.length);
        }
    });
    
    fs.writeFileSync('/tmp/adrock_frame5_lottie_web.svg', svgElement ? svgElement.outerHTML : '');
    console.log('Written to /tmp/adrock_frame5_lottie_web.svg');
});
