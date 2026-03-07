const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

const dom = new JSDOM('<!DOCTYPE html><html><body><div id="container"></div></body></html>', {
    pretendToBeVisual: true
});
global.window = dom.window;
global.document = dom.window.document;
global.navigator = dom.window.navigator;
global.Node = dom.window.Node;
global.Element = dom.window.Element;
global.HTMLDivElement = dom.window.HTMLDivElement;

dom.window.HTMLCanvasElement.prototype.getContext = function() {
    return {
        fillRect: () => {},
        clearRect: () => {},
        getImageData: (x, y, w, h) => ({ data: new Uint8ClampedArray(w * h * 4) }),
        putImageData: () => {},
        createImageData: () => ([]),
        setTransform: () => {},
        drawImage: () => {},
        save: () => {},
        restore: () => {},
        beginPath: () => {},
        moveTo: () => {},
        lineTo: () => {},
        closePath: () => {},
        stroke: () => {},
        translate: () => {},
        scale: () => {},
        rotate: () => {},
        arc: () => {},
        fill: () => {},
        measureText: () => ({ width: 0 }),
        transform: () => {},
        rect: () => {},
        clip: () => {},
    };
};

const lottie = require('./node_modules/lottie-web');
const animData = JSON.parse(fs.readFileSync('../../samples/1_6_Designer.json', 'utf8'));
const container = document.getElementById('container');

const anim = lottie.loadAnimation({
    container: container,
    renderer: 'svg',
    loop: false,
    autoplay: false,
    animationData: animData,
});

anim.addEventListener('DOMLoaded', () => {
    anim.goToAndStop(62, true);
    
    const svgEl = container.querySelector('svg');
    let svgString = svgEl.outerHTML;
    svgString = svgString.replace(/id="[^"]*"/g, 'id="lottie-id"');
    svgString = svgString.replace(/url\(#[^)]*\)/g, 'url(#lottie-id)');
    
    fs.writeFileSync('/tmp/designer_frame62_lottie.svg', svgString);
    console.log('Saved lottie-web SVG for frame 62, length:', svgString.length);
    
    anim.destroy();
    process.exit(0);
});
