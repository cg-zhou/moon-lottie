const sharp = require('./node_modules/sharp');
const fs = require('fs');
const path = require('path');
const { chromium } = require('./node_modules/playwright');

async function main() {
    // Generate zoomed comparison at multiple frames
    const browser = await chromium.launch({
        headless: true,
        executablePath: '/home/runner/.cache/ms-playwright/chromium_headless_shell-1208/chrome-headless-shell-linux64/chrome-headless-shell'
    });
    
    const repoRoot = path.resolve(__dirname, '../..');
    const http = require('http');
    const mimeTypes = { '.html': 'text/html', '.js': 'application/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.css': 'text/css' };
    
    const server = await new Promise((resolve) => {
        const s = http.createServer((req, res) => {
            const urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
            const rel = urlPath === '/' ? '/demo/index.html' : urlPath;
            const filePath = path.resolve(repoRoot, '.' + rel);
            if (!filePath.startsWith(path.resolve(repoRoot))) { res.writeHead(403); res.end('Forbidden'); return; }
            fs.readFile(filePath, (err, data) => {
                if (err) { res.writeHead(404); res.end('Not found'); return; }
                const ext = path.extname(filePath).toLowerCase();
                res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'application/octet-stream' });
                res.end(data);
            });
        });
        s.listen(4173, '127.0.0.1', () => resolve(s));
    });
    
    const page = await browser.newPage({ viewport: { width: 1400, height: 900 } });
    const localLottiePath = path.join(__dirname, 'node_modules/lottie-web/build/player/lottie.min.js');
    await page.route('https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js', (route) => {
        route.fulfill({ status: 200, contentType: 'application/javascript; charset=utf-8', body: fs.readFileSync(localLottiePath, 'utf8') });
    });
    
    await page.goto('http://127.0.0.1:4173/demo/index.html', { waitUntil: 'networkidle' });
    await page.selectOption('#anim-list', '1_6_Designer.json');
    await page.waitForSelector('#official-lottie-container canvas', { timeout: 15000, state: 'attached' });
    
    for (const frame of [52, 62]) {
        await page.evaluate(({ f }) => {
            const compareToggle = document.getElementById('compare-toggle');
            if (compareToggle && !compareToggle.checked) compareToggle.click();
            const playPause = document.getElementById('play-pause');
            if (playPause && playPause.innerText === '\u2016') playPause.click();
            const seekBar = document.getElementById('seek-bar');
            seekBar.value = String(f);
            seekBar.dispatchEvent(new Event('input', { bubbles: true }));
        }, { f: frame });
        
        await page.waitForTimeout(500);
        
        const moonCanvas = page.locator('#lottie-canvas');
        const officialCanvas = page.locator('#official-lottie-container canvas').first();
        
        await moonCanvas.screenshot({ path: `/tmp/moon_${frame}.png` });
        await officialCanvas.screenshot({ path: `/tmp/official_${frame}.png` });
        console.log(`Saved frame ${frame}`);
    }
    
    await browser.close();
    server.close();
    
    // Generate zoomed crops of the right side (person figure)
    // The person is roughly at x=300-490, y=200-460 in a 490x490 viewport
    const cropOpts = { left: 280, top: 180, width: 210, height: 280 };
    
    for (const frame of [52, 62]) {
        for (const prefix of ['moon', 'official']) {
            await sharp(`/tmp/${prefix}_${frame}.png`)
                .extract(cropOpts)
                .resize(420, 560)
                .toFile(`/tmp/zoomed_${prefix}_${frame}.png`);
        }
        
        // Also generate diff
        const exp = await sharp(`/tmp/official_${frame}.png`).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
        const act = await sharp(`/tmp/moon_${frame}.png`).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
        const pixelmatch = require('./node_modules/pixelmatch').default || require('./node_modules/pixelmatch');
        const w = exp.info.width, h = exp.info.height;
        const diff = Buffer.alloc(w * h * 4);
        const mismatched = pixelmatch(exp.data, act.data, diff, w, h, { threshold: 0.1, includeAA: true });
        await sharp(diff, { raw: { width: w, height: h, channels: 4 } }).extract(cropOpts).resize(420, 560).png().toFile(`/tmp/zoomed_diff_${frame}.png`);
        console.log(`Frame ${frame}: ${((1-mismatched/(w*h))*100).toFixed(2)}% similar`);
    }
}
main().catch(e => { console.error(e); process.exit(1); });
