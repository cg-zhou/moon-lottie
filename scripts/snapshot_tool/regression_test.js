const fs = require('fs');
const path = require('path');
const http = require('http');
const { spawnSync } = require('child_process');
const sharp = require('sharp');
const pixelmatchModule = require('pixelmatch');
const { chromium } = require('playwright');

const pixelmatch = pixelmatchModule.default || pixelmatchModule;
const CANVAS_RENDER_DELAY_MS = 120;
const PAUSE_BUTTON_TEXT = '‖';

function arg(name, fallback = undefined) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1 || idx + 1 >= process.argv.length) return fallback;
  return process.argv[idx + 1];
}

function parseCaseConfig(content) {
  return content
    .split(/\r?\n/)
    .map((line, index) => ({ line: line.trim(), lineNo: index + 1 }))
    .filter(item => item.line && !item.line.startsWith('#'))
    .map(({ line, lineNo }) => {
      const parts = line.split(/\s+/).filter(Boolean);
      if (parts.length < 2) {
        throw new Error(`Invalid case line ${lineNo}: ${line}`);
      }
      
      let minSimilarity = 0.0;
      let frameStartIndex = 1;
      
      // Check if the second part is a similarity value like "sim=0.99"
      if (parts[1].startsWith('sim=')) {
        minSimilarity = Number(parts[1].split('=')[1]);
        if (!Number.isFinite(minSimilarity) || minSimilarity < 0 || minSimilarity > 1) {
          throw new Error(`Invalid similarity value in line ${lineNo}: ${parts[1]}`);
        }
        frameStartIndex = 2;
      }

      const file = parts[0];
      const frames = parts.slice(frameStartIndex).map(v => {
        const frame = Number(v);
        if (!Number.isFinite(frame) || frame < 0) {
          throw new Error(`Invalid frame '${v}' at line ${lineNo}`);
        }
        return Math.floor(frame);
      });
      return { file, frames, minSimilarity };
    });
}

function ensureWasmBuilt(repoRoot) {
  const wasmPath = path.join(repoRoot, '_build/wasm-gc/debug/build/cmd/main/main.wasm');
  if (fs.existsSync(wasmPath)) {
    return;
  }
  console.log('[BUILD] main.wasm not found, running moon build --target wasm-gc ...');
  const result = spawnSync('moon', ['build', '--target', 'wasm-gc'], {
    cwd: repoRoot,
    stdio: 'inherit'
  });
  if (result.status !== 0) {
    throw new Error('Failed to build wasm target with moon build --target wasm-gc');
  }
}

function createStaticServer(rootDir, port) {
  const mimeTypes = {
    '.html': 'text/html; charset=utf-8',
    '.js': 'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.wasm': 'application/wasm',
    '.css': 'text/css; charset=utf-8',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.svg': 'image/svg+xml; charset=utf-8'
  };

  const server = http.createServer((req, res) => {
    const urlPath = decodeURIComponent((req.url || '/').split('?')[0]);
    const relativePath = urlPath === '/' ? '/demo/index.html' : urlPath;
    const filePath = path.resolve(rootDir, `.${relativePath}`);

    if (!filePath.startsWith(path.resolve(rootDir))) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }

    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      const ext = path.extname(filePath).toLowerCase();
      res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'application/octet-stream' });
      res.end(data);
    });
  });

  return new Promise((resolve, reject) => {
    server.on('error', reject);
    server.listen(port, '127.0.0.1', () => resolve(server));
  });
}

async function comparePngFiles(expectedPath, actualPath, diffPath) {
  const expectedRaw0 = await sharp(expectedPath).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const actualRaw0 = await sharp(actualPath).ensureAlpha().raw().toBuffer({ resolveWithObject: true });

  const expectedRaw = {
    data: expectedRaw0.data,
    width: expectedRaw0.info.width,
    height: expectedRaw0.info.height,
  };

  const actualRaw = (actualRaw0.info.width === expectedRaw.width && actualRaw0.info.height === expectedRaw.height)
    ? { data: actualRaw0.data, width: actualRaw0.info.width, height: actualRaw0.info.height }
    : await sharp(actualRaw0.data, {
      raw: { width: actualRaw0.info.width, height: actualRaw0.info.height, channels: 4 }
    }).resize(expectedRaw.width, expectedRaw.height).raw().toBuffer().then(data => ({
      data,
      width: expectedRaw.width,
      height: expectedRaw.height,
    }));

  const diff = Buffer.alloc(expectedRaw.width * expectedRaw.height * 4);
  const mismatched = pixelmatch(
    expectedRaw.data,
    actualRaw.data,
    diff,
    expectedRaw.width,
    expectedRaw.height,
    { threshold: 0.1, includeAA: true }
  );

  const total = expectedRaw.width * expectedRaw.height;
  const similarity = 1.0 - mismatched / total;

  await sharp(diff, {
    raw: { width: expectedRaw.width, height: expectedRaw.height, channels: 4 }
  }).png().toFile(diffPath);

  return { mismatched, total, similarity };
}

async function setAndCaptureFrame(page, filename, frame, outputDir) {
  const base = path.parse(filename).name;
  const moonPath = path.join(outputDir, `${base}_${frame}.png`);
  const officialPath = path.join(outputDir, `${base}_${frame}_official.png`);
  const diffPath = path.join(outputDir, `${base}_${frame}_diff.png`);

  await page.selectOption('#anim-list', filename);
  await page.waitForSelector('#official-lottie-container canvas', { timeout: 15000, state: 'attached' });

  await page.evaluate(({ f, pauseButtonText }) => {
    const compareToggle = document.getElementById('compare-toggle');
    if (compareToggle && !compareToggle.checked) {
      compareToggle.click();
    }

    const playPause = document.getElementById('play-pause');
    if (playPause && playPause.innerText === pauseButtonText) {
      playPause.click();
    }

    const seekBar = document.getElementById('seek-bar');
    seekBar.value = String(f);
    seekBar.dispatchEvent(new Event('input', { bubbles: true }));
  }, { f: frame, pauseButtonText: PAUSE_BUTTON_TEXT });

  await page.waitForTimeout(CANVAS_RENDER_DELAY_MS);

  const moonCanvas = page.locator('#lottie-canvas');
  const officialCanvas = page.locator('#official-lottie-container canvas').first();

  await moonCanvas.screenshot({ path: moonPath });
  await officialCanvas.screenshot({ path: officialPath });

  const result = await comparePngFiles(officialPath, moonPath, diffPath);
  return { moonPath, officialPath, diffPath, result };
}

async function main() {
  const caseFileArg = arg('cases', './cases.txt');
  const caseFile = path.resolve(process.cwd(), caseFileArg);
  const port = Number(arg('port', '4173'));
  // Global override if provided, otherwise using sim=... from cases.txt
  const globalMinSimilarity = arg('min-similarity') ? Number(arg('min-similarity')) : null;
  const outputDirArg = arg('output-dir', '');
  const outputDir = outputDirArg
    ? path.resolve(process.cwd(), outputDirArg)
    : path.resolve(process.cwd(), 'frame_compare_result');

  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const repoRoot = path.resolve(__dirname, '../..');
  const samplesDir = path.join(repoRoot, 'samples');

  if (!fs.existsSync(caseFile)) {
    throw new Error(`Case config file not found: ${caseFile}`);
  }

  const cases = parseCaseConfig(fs.readFileSync(caseFile, 'utf8'));
  cases.forEach(item => {
    const samplePath = path.join(samplesDir, item.file);
    if (!fs.existsSync(samplePath)) {
      throw new Error(`Sample file not found: ${item.file}`);
    }
  });

  ensureWasmBuilt(repoRoot);

  console.log(`[INFO] Case file: ${caseFile}`);
  console.log(`[INFO] Output directory: ${outputDir}`);

  const server = await createStaticServer(repoRoot, port);
  const browser = await chromium.launch({
    headless: true,
  });
  const page = await browser.newPage({ viewport: { width: 1400, height: 900 } });
  const localLottiePathCandidates = [
    path.join(__dirname, 'node_modules/lottie-web/build/player/lottie.min.js'),
    path.join(repoRoot, 'node_modules/lottie-web/build/player/lottie.min.js'),
  ];
  const localLottiePath = localLottiePathCandidates.find(p => fs.existsSync(p));
  if (!localLottiePath) {
    throw new Error('Local lottie-web script not found. Run npm install in scripts/snapshot_tool first.');
  }
  await page.route('https://cdnjs.cloudflare.com/ajax/libs/lottie-web/5.12.2/lottie.min.js', (route) => {
    route.fulfill({
      status: 200,
      contentType: 'application/javascript; charset=utf-8',
      body: fs.readFileSync(localLottiePath, 'utf8'),
    });
  });

  let allPassed = true;
  let totalSimilarity = 0;
  let totalCompares = 0;

  try {
    await page.goto(`http://127.0.0.1:${port}/demo/index.html`, { waitUntil: 'networkidle' });
    await page.waitForFunction(
      () => document.querySelectorAll('#anim-list option').length > 0,
      { timeout: 15000 }
    );
    const hasLottie = await page.evaluate(() => !!window.lottie);
    if (!hasLottie) {
      throw new Error('Failed to load lottie-web in browser page');
    }

    for (const item of cases) {
      const currentMinSim = globalMinSimilarity !== null ? globalMinSimilarity : item.minSimilarity;

      for (const frame of item.frames) {
        const { result } = await setAndCaptureFrame(page, item.file, frame, outputDir);
        const similarityPct = (result.similarity * 100).toFixed(4);
        const minSimPct = (currentMinSim * 100).toFixed(2);
        
        const isPassed = result.similarity >= currentMinSim;
        const colorPrefix = isPassed ? '\x1b[32m' : '\x1b[31m'; // 32m: Green, 31m: Red
        const colorSuffix = '\x1b[0m';
        
        console.log(
          `${colorPrefix}[COMPARE] ${item.file} frame=${frame} similarity=${similarityPct}% (min=${minSimPct}%)${colorSuffix}`
        );
        
        totalSimilarity += result.similarity;
        totalCompares++;

        if (!isPassed) {
          allPassed = false;
        }
      }
    }
  } finally {
    await browser.close();
    await new Promise(resolve => server.close(resolve));
  }

  if (totalCompares > 0) {
    const avgSimilarity = (totalSimilarity / totalCompares * 100).toFixed(4);
    console.log(`\n[SUMMARY] Avg Similarity: ${avgSimilarity}% over ${totalCompares} checks`);
  }

  if (!allPassed) {
    throw new Error(`Frame comparison failed.`);
  }
}

if (require.main === module) {
  main().catch(err => {
    console.error(err.message || err);
    process.exit(1);
  });
}

module.exports = {
  parseCaseConfig,
};
