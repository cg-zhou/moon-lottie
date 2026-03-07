/**
 * Generates visual comparison screenshots for 1_6_Designer.json at frame 62
 */
const fs = require('fs');
const path = require('path');
const { chromium } = require('./node_modules/playwright');

async function main() {
    const frame = 62;
    
    const browser = await chromium.launch({
        headless: true,
        executablePath: '/home/runner/.cache/ms-playwright/chromium_headless_shell-1208/chrome-headless-shell-linux64/chrome-headless-shell'
    });
    
    const page = await browser.newPage({ viewport: { width: 1400, height: 900 } });
    
    const localLottiePath = path.join(__dirname, 'node_modules/lottie-web/build/player/lottie.min.js');
    await page.route('https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js', (route) => {
        route.fulfill({
            status: 200,
            contentType: 'application/javascript; charset=utf-8',
            body: fs.readFileSync(localLottiePath, 'utf8'),
        });
    });
    
    const repoRoot = path.resolve(__dirname, '../..');
    const http = require('http');
    const mimeTypes = { '.html': 'text/html', '.js': 'application/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.css': 'text/css' };
    
    const server = await new Promise((resolve) => {
        const s = http.createServer((req, res) => {
            const urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
            const rel = urlPath === '/' ? '/demo/index.html' : urlPath;
            const filePath = path.resolve(repoRoot, '.' + rel);
            if (!filePath.startsWith(path.resolve(repoRoot))) {
                res.writeHead(403); res.end('Forbidden'); return;
            }
            fs.readFile(filePath, (err, data) => {
                if (err) { res.writeHead(404); res.end('Not found'); return; }
                const ext = path.extname(filePath).toLowerCase();
                res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'application/octet-stream' });
                res.end(data);
            });
        });
        s.listen(4173, '127.0.0.1', () => resolve(s));
    });
    
    await page.goto('http://127.0.0.1:4173/demo/index.html', { waitUntil: 'networkidle' });
    
    // Select designer animation
    await page.selectOption('#anim-list', '1_6_Designer.json');
    await page.waitForSelector('#official-lottie-container canvas', { timeout: 15000, state: 'attached' });
    
    // Enable compare mode and seek to frame 62
    await page.evaluate(({ f }) => {
        const compareToggle = document.getElementById('compare-toggle');
        if (compareToggle && !compareToggle.checked) compareToggle.click();
        const playPause = document.getElementById('play-pause');
        if (playPause && playPause.innerText === '\u2016') playPause.click(); // pause if playing
        const seekBar = document.getElementById('seek-bar');
        seekBar.value = String(f);
        seekBar.dispatchEvent(new Event('input', { bubbles: true }));
    }, { f: frame });
    
    await page.waitForTimeout(500);
    
    // Screenshot both canvases
    const moonCanvas = page.locator('#lottie-canvas');
    const officialCanvas = page.locator('#official-lottie-container canvas').first();
    
    await moonCanvas.screenshot({ path: '/tmp/moon_designer_62.png' });
    await officialCanvas.screenshot({ path: '/tmp/official_designer_62.png' });
    
    console.log('Saved screenshots to /tmp/moon_designer_62.png and /tmp/official_designer_62.png');
    
    // Generate diff
    const sharp = require('./node_modules/sharp');
    const pixelmatchModule = require('./node_modules/pixelmatch');
    const pixelmatch = pixelmatchModule.default || pixelmatchModule;
    
    const expected = await sharp('/tmp/official_designer_62.png').ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    const actual = await sharp('/tmp/moon_designer_62.png').ensureAlpha().raw().toBuffer({ resolveWithObject: true });
    
    const w = expected.info.width;
    const h = expected.info.height;
    const diff = Buffer.alloc(w * h * 4);
    
    const mismatched = pixelmatch(expected.data, actual.data, diff, w, h, { threshold: 0.1, includeAA: true });
    const similarity = 1.0 - mismatched / (w * h);
    
    await sharp(diff, { raw: { width: w, height: h, channels: 4 } }).png().toFile('/tmp/diff_designer_62.png');
    
    console.log(`Similarity: ${(similarity * 100).toFixed(2)}% (mismatched: ${mismatched}/${w*h})`);
    
    await browser.close();
    server.close();
}

main().catch(e => { console.error(e.message || e); process.exit(1); });
