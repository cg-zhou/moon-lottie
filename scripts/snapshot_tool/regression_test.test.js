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

test('expression animations prefer official frontend renderer', async () => {
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

  assert.equal(helper.getPreferredRendererMode({
    ks: {
      p: {
        s: true,
        x: { a: 0, k: 100 },
        y: { a: 0, k: 200 },
      },
    },
  }), 'wasm');

  assert.equal(helper.getPreferredRendererMode({
    shapes: [{ ks: { x: 'loopOut()' } }],
  }), 'official');
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
