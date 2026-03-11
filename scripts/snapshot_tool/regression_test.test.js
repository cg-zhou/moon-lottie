const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { parseCaseConfig } = require('./regression_test');

test('parseCaseConfig parses file and frames', () => {
  const input = [
    '# comment',
    '1_1_Super_Mario.json 23 46',
    '',
    'bacon.json 0 10 20',
  ].join('\n');

  const cases = parseCaseConfig(input);
  assert.deepEqual(cases, [
    { file: '1_1_Super_Mario.json', frames: [23, 46], minSimilarity: 0 },
    { file: 'bacon.json', frames: [0, 10, 20], minSimilarity: 0 },
  ]);
});

test('parseCaseConfig rejects invalid line', () => {
  assert.throws(() => parseCaseConfig('only_filename.json'), /Invalid case line/);
  assert.throws(() => parseCaseConfig('a.json x'), /Invalid frame/);
});

test('parseCaseConfig parses explicit similarity thresholds', () => {
  const cases = parseCaseConfig('sample.json sim=0.95 12 24');

  assert.deepEqual(cases, [
    { file: 'sample.json', frames: [12, 24], minSimilarity: 0.95 },
  ]);
});

test('demo uses vendored lottie-web asset', () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const html = fs.readFileSync(path.join(repoRoot, 'demo', 'index.html'), 'utf8');
  const workflow = fs.readFileSync(path.join(repoRoot, '.github', 'workflows', 'deploy-pages.yml'), 'utf8');

  assert.match(html, /<script src="\.\/lottie\.min\.js"><\/script>/);
  assert.match(workflow, /cp demo\/lottie\.min\.js \/tmp\/demo_dist\//);
  assert.ok(fs.existsSync(path.join(repoRoot, 'demo', 'lottie.min.js')));
});

test('expression detection finds string-valued expression fields', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const helper = await import(path.join(repoRoot, 'demo', 'render_mode.mjs'));

  assert.equal(helper.animationUsesExpressions({
    ks: {
      p: {
        a: 1,
        k: [{ t: 0, s: [0, 0, 0] }],
        x: 'value + [10, 20, 0]',
      },
    },
  }), true);
});

test('expression helper computes playback metadata from animation root', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const helper = await import(path.join(repoRoot, 'demo', 'render_mode.mjs'));

  const meta = helper.getAnimationPlaybackMeta({
    v: '5.12.2',
    fr: 60,
    ip: 10,
    op: 190,
    w: 512,
    h: 256,
  });

  assert.deepEqual(meta, {
    version: '5.12.2',
    width: 512,
    height: 256,
    fps: 60,
    inPoint: 10,
    outPoint: 190,
    totalFrames: 180,
    aspectRatio: '512 / 256',
  });
});

test('default expression host evaluates scalar expressions with layer effects context', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.mjs'));

  const animationData = {
    fr: 60,
    w: 512,
    h: 512,
    layers: [{
      ind: 6,
      ef: [{
        nm: 'Position - Overshoot',
        ef: [{
          mn: 'ADBE Slider Control-0001',
          v: { a: 0, k: 20 },
        }],
      }],
      ks: {
        p: {
          a: 1,
          k: [
            { t: 0, s: [0, 0, 0], e: [60, 0, 0] },
            { t: 60, s: [60, 0, 0], e: [120, 0, 0] },
          ],
          x: "var $bm_rt; $bm_rt = effect('Position - Overshoot')('ADBE Slider Control-0001') + time;",
        },
      },
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  const result = host.evaluateDouble(
    "var $bm_rt; $bm_rt = effect('Position - Overshoot')('ADBE Slider Control-0001') + time;",
    30,
    6,
    0,
  );

  assert.equal(result, 20.5);
});

test('default expression host evaluates vector expressions', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.mjs'));

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => ({ fr: 30, layers: [{ ind: 2 }] }),
    getPlaybackMeta: () => ({ fps: 30 }),
  });

  const value = host.evaluateVec('var $bm_rt; $bm_rt = sum(value, [5, -5, 0]);', 12, 2, [10, 20, 0]);

  assert.deepEqual(value, [15, 15, 0]);
});

test('default expression host supports createPath-style path mutations', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.mjs'));

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => ({ fr: 30, layers: [{ ind: 15 }] }),
    getPlaybackMeta: () => ({ fps: 30 }),
  });

  const pathValue = host.evaluatePath(
    'var $bm_rt; var pts = thisProperty.points(); pts[1] = [20, 5]; $bm_rt = createPath(pts, thisProperty.inTangents(), thisProperty.outTangents(), true);',
    0,
    15,
    {
      vertices: [[0, 0], [10, 0]],
      inTangents: [[0, 0], [0, 0]],
      outTangents: [[0, 0], [0, 0]],
      closed: false,
    },
  );

  assert.equal(pathValue.closed, true);
  assert.deepEqual(pathValue.vertices, [[0, 0], [20, 5]]);
});
