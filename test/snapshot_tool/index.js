const fs = require('fs');
const path = require('path');
const { JSDOM } = require('jsdom');

// 1. Setup JSDOM environment for lottie-web
const dom = new JSDOM('<!DOCTYPE html><html><body><div id="container"></div></body></html>', {
    pretendToBeVisual: true
});
global.window = dom.window;
global.document = dom.window.document;
global.navigator = dom.window.navigator;
global.Node = dom.window.Node;
global.Element = dom.window.Element;
global.HTMLDivElement = dom.window.HTMLDivElement;

// Mock Canvas for lottie-web in JSDOM environment
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

const lottie = require('lottie-web');

const fixturesDir = path.join(__dirname, '../../samples');
const outputDir = path.join(__dirname, '../snapshots');

if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}

async function generateSnapshots(filename) {
    console.log(`Processing: ${filename}...`);
    const filePath = path.join(fixturesDir, filename);
    const animationData = JSON.parse(fs.readFileSync(filePath, 'utf8'));

    const container = document.getElementById('container');
    container.innerHTML = ''; // Clear previous

    const anim = lottie.loadAnimation({
        container: container,
        renderer: 'svg',
        loop: false,
        autoplay: false,
        animationData: animationData,
    });

    // Wait for animation to be ready
    await new Promise(resolve => {
        anim.addEventListener('DOMLoaded', resolve);
    });

    const totalFrames = anim.totalFrames;
    const samplePoints = [0, 0.25, 0.5, 0.75, 0.99]; // 0.99 to avoid out of bounds in some engines

    for (const p of samplePoints) {
        const frame = Math.floor(totalFrames * p);
        anim.goToAndStop(frame, true);
        
        // Let lottie update the DOM
        const svgElement = container.querySelector('svg');
        let svgString = svgElement.outerHTML;

        // Cleanup: remove dynamic IDs that change every run
        svgString = svgString.replace(/id="[^"]*"/g, 'id="lottie-id"');
        svgString = svgString.replace(/url\(#[^)]*\)/g, 'url(#lottie-id)');

        const outputFileName = `${path.parse(filename).name}_frame_${Math.floor(p * 100)}.svg`;
        const outputPath = path.join(outputDir, outputFileName);
        
        fs.writeFileSync(outputPath, svgString);
        console.log(`  Saved: ${outputFileName}`);
    }

    anim.destroy();
}

async function main() {
    const files = fs.readdirSync(fixturesDir).filter(f => f.endsWith('.json'));
    for (const file of files) {
        try {
            await generateSnapshots(file);
        } catch (e) {
            console.error(`Error processing ${file}:`, e.message);
        }
    }
    console.log('\nGolden snapshots generated successfully in test_data/golden/');
}

main();
