const fs = require('fs');
const path = require('path');
const sharp = require('sharp');
const { default: pixelmatch } = require('pixelmatch');

function arg(name, fallback = undefined) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1 || idx + 1 >= process.argv.length) return fallback;
  return process.argv[idx + 1];
}

function parseList(v) {
  if (!v) return [];
  return v.split(',').map(s => s.trim()).filter(Boolean);
}

async function svgToRaw(svgString) {
  const image = sharp(Buffer.from(svgString));
  const meta = await image.metadata();
  const width = meta.width || 0;
  const height = meta.height || 0;
  if (width <= 0 || height <= 0) {
    throw new Error('Invalid SVG size');
  }
  const { data, info } = await image.ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  return { data, width: info.width, height: info.height };
}

async function compareSvgFiles(expectedPath, actualPath, diffPath) {
  const expectedSvg = fs.readFileSync(expectedPath, 'utf8');
  const actualSvg = fs.readFileSync(actualPath, 'utf8');
  const expectedRaw = await svgToRaw(expectedSvg);
  const actualRaw0 = await svgToRaw(actualSvg);

  const actualRaw = actualRaw0.width === expectedRaw.width && actualRaw0.height === expectedRaw.height
    ? actualRaw0
    : await sharp(actualRaw0.data, {
      raw: { width: actualRaw0.width, height: actualRaw0.height, channels: 4 }
    }).resize(expectedRaw.width, expectedRaw.height).raw().toBuffer().then(data => ({
      data,
      width: expectedRaw.width,
      height: expectedRaw.height
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

  if (diffPath) {
    await sharp(diff, {
      raw: { width: expectedRaw.width, height: expectedRaw.height, channels: 4 }
    }).png().toFile(diffPath);
  }

  return { mismatched, total, similarity };
}

async function main() {
  const expectedDir = arg('expected-dir', path.join(__dirname, '../snapshots'));
  const actualDir = arg('actual-dir', path.join(__dirname, '../snapshots'));
  const files = parseList(arg('files', '1-1 Super Mario_frame_25.svg,1-1 Super Mario_frame_50.svg,1-1 Super Mario_frame_75.svg'));
  const minSimilarity = Number(arg('min-similarity', '0.995'));
  const diffDir = arg('diff-dir', path.join(__dirname, '../snapshots_diff'));

  if (!fs.existsSync(diffDir)) fs.mkdirSync(diffDir, { recursive: true });

  let allPassed = true;
  for (const file of files) {
    const expectedPath = path.join(expectedDir, file);
    const actualPath = path.join(actualDir, file);
    if (!fs.existsSync(expectedPath) || !fs.existsSync(actualPath)) {
      console.error(`[MISSING] ${file}`);
      allPassed = false;
      continue;
    }

    const diffPath = path.join(diffDir, `${path.parse(file).name}.diff.png`);
    const result = await compareSvgFiles(expectedPath, actualPath, diffPath);
    console.log(
      `[COMPARE] ${file} similarity=${(result.similarity * 100).toFixed(4)}% mismatched=${result.mismatched}/${result.total} diff=${diffPath}`
    );
    if (result.similarity < minSimilarity) {
      allPassed = false;
    }
  }

  if (!allPassed) {
    process.exitCode = 1;
    throw new Error(`Frame comparison failed: min similarity=${minSimilarity}`);
  }
}

main().catch(err => {
  console.error(err.message || err);
  process.exit(1);
});
