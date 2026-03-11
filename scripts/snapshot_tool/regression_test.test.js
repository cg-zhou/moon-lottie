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

test('default expression host resolves thisComp.layer and thisLayer.effect lookups', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.mjs'));

  const animationData = {
    fr: 60,
    layers: [
      {
        ind: 7,
        nm: 'color',
        ef: [{
          nm: 'color linea',
          ef: [{ nm: 'Color', v: { a: 0, k: [0.1, 0.2, 0.3, 1] } }],
        }],
      },
      {
        ind: 9,
        nm: 'traceNull',
        ef: [{
          nm: 'Pseudo/ADBE Trace Path',
          ef: [{ mn: 'Pseudo/ADBE Trace Path-0001', v: { a: 0, k: 25 } }],
        }],
        ks: { p: { a: 0, k: [11, 22, 0] } },
      },
    ],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  const color = host.evaluateVec(
    "var $bm_rt; $bm_rt = thisComp.layer('color').effect('color linea')('Color');",
    0,
    9,
    [0, 0, 0, 0],
  );
  const progress = host.evaluateDouble(
    "var $bm_rt; $bm_rt = thisLayer.effect('Pseudo/ADBE Trace Path')('Pseudo/ADBE Trace Path-0001') + thisLayer.index;",
    0,
    9,
    0,
  );

  assert.deepEqual(color, [0.1, 0.2, 0.3, 1]);
  assert.equal(progress, 34);
});

test('default expression host resolves maskPath access through thisComp.layer', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.mjs'));

  const animationData = {
    fr: 30,
    layers: [{
      ind: 3,
      nm: 'monster',
      masksProperties: [{
        nm: 'Mask 1',
        pt: {
          a: 0,
          k: {
            v: [[0, 0], [20, 5], [10, 10]],
            i: [[0, 0], [0, 0], [0, 0]],
            o: [[0, 0], [0, 0], [0, 0]],
            c: true,
          },
        },
      }],
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 30 }),
  });

  const value = host.evaluateVec(
    "var $bm_rt; $bm_rt = thisComp.layer('monster').mask('Mask 1').maskPath.points()[1];",
    0,
    3,
    [0, 0],
  );

  assert.deepEqual(value, [20, 5]);
});

test('default expression host resolves content path lookup and toComp projection', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.mjs'));

  const animationData = {
    fr: 60,
    layers: [{
      ind: 12,
      nm: 'wire',
      ks: {
        p: { a: 0, k: [0, 10, 0] },
        a: { a: 0, k: [0, 0, 0] },
        s: { a: 0, k: [100, 100, 100] },
        r: { a: 0, k: 0 },
      },
      shapes: [{
        ty: 'gr',
        nm: 'Group 1',
        it: [{
          ty: 'sh',
          nm: 'Path 1',
          ks: {
            a: 0,
            k: {
              v: [[0, 0], [100, 0]],
              i: [[0, 0], [0, 0]],
              o: [[0, 0], [0, 0]],
              c: false,
            },
          },
        }],
      }],
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  const point = host.evaluateVec(
    "var $bm_rt; var pathLayer = thisComp.layer('wire'); var pathToTrace = pathLayer('ADBE Root Vectors Group')(1)('ADBE Vectors Group')(1)('ADBE Vector Shape'); $bm_rt = pathLayer.toComp(pathToTrace.pointOnPath(0.5));",
    0,
    12,
    [0, 0, 0],
  );
  const angle = host.evaluateDouble(
    "var $bm_rt; var pathToTrace = thisComp.layer('wire')('ADBE Root Vectors Group')(1)('ADBE Vectors Group')(1)('ADBE Vector Shape'); var pathTan = pathToTrace.tangentOnPath(0.5); $bm_rt = radiansToDegrees(Math.atan2(pathTan[1], pathTan[0]));",
    0,
    12,
    0,
  );

  assert.deepEqual(point, [50, 10, 0]);
  assert.equal(angle, 0);
});

test('default expression host resolves layer control effects and fromCompToSurface in path expressions', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.mjs'));

  const animationData = {
    fr: 60,
    layers: [
      {
        ind: 1,
        nm: 'null-a',
        ks: {
          a: { a: 0, k: [5, 0, 0] },
          p: { a: 0, k: [100, 50, 0] },
          s: { a: 0, k: [100, 100, 100] },
          r: { a: 0, k: 0 },
        },
      },
      {
        ind: 2,
        nm: 'wire',
        ef: [{
          nm: 'Control A',
          mn: 'ADBE Layer Control',
          ef: [{ mn: 'ADBE Layer Control-0001', v: { a: 0, k: 1 } }],
        }],
        ks: {
          a: { a: 0, k: [0, 0, 0] },
          p: { a: 0, k: [10, 0, 0] },
          s: { a: 0, k: [100, 100, 100] },
          r: { a: 0, k: 0 },
        },
      },
    ],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  const pathValue = host.evaluatePath(
    "var $bm_rt; var target = effect('Control A')('ADBE Layer Control-0001'); var pts = thisProperty.points(); pts[0] = fromCompToSurface(target.toComp(target.anchorPoint)); $bm_rt = createPath(pts, thisProperty.inTangents(), thisProperty.outTangents(), thisProperty.isClosed());",
    0,
    2,
    {
      vertices: [[0, 0], [10, 0]],
      inTangents: [[0, 0], [0, 0]],
      outTangents: [[0, 0], [0, 0]],
      closed: false,
    },
  );

  assert.deepEqual(pathValue.vertices[0], [90, 50, 0]);
});

test('default expression host exposes bare loopOut helper with cycle semantics', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.mjs'));

  const expression = "var $bm_rt; $bm_rt = loopOut('cycle');";
  const animationData = {
    fr: 30,
    layers: [{
      ind: 20,
      ks: {
        r: {
          a: 1,
          k: [
            { t: 0, s: [0], e: [100] },
            { t: 60, s: [100], e: [0] },
            { t: 120 },
          ],
          x: expression,
        },
      },
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 30 }),
  });

  assert.equal(host.evaluateDouble(expression, 150, 20, 0), 50);
});

test('default expression host supports loopOut offset and pingpong modes', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.mjs'));

  const offsetExpression = "var $bm_rt; $bm_rt = loopOut('offset');";
  const pingPongExpression = "var $bm_rt; $bm_rt = loopOut('pingpong');";
  const animationData = {
    fr: 30,
    layers: [{
      ind: 21,
      ks: {
        r: {
          a: 1,
          k: [
            { t: 0, s: [0], e: [100] },
            { t: 60, s: [100], e: [200] },
            { t: 120 },
          ],
          x: offsetExpression,
        },
        o: {
          a: 1,
          k: [
            { t: 0, s: [0], e: [100] },
            { t: 60, s: [100], e: [0] },
            { t: 120 },
          ],
          x: pingPongExpression,
        },
      },
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 30 }),
  });

  assert.equal(host.evaluateDouble(offsetExpression, 150, 21, 0), 250);
  assert.equal(host.evaluateDouble(pingPongExpression, 150, 21, 0), 50);
});

test('default expression host supports loopIn hold mode', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.mjs'));

  const expression = "var $bm_rt; $bm_rt = loopIn('hold');";
  const animationData = {
    fr: 30,
    layers: [{
      ind: 22,
      ks: {
        r: {
          a: 1,
          k: [
            { t: 30, s: [10], e: [30] },
            { t: 90, s: [30], e: [60] },
            { t: 150 },
          ],
          x: expression,
        },
      },
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 30 }),
  });

  assert.equal(host.evaluateDouble(expression, 0, 22, 0), 10);
});

test('default expression host resolves thisComp.layer within the current precomp scope', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.mjs'));

  const barLookupExpression = "var $bm_rt; var barLayer, barPath; barLayer = thisComp.layer('bar'); barPath = barLayer.content('Path 1').path.points(); $bm_rt = barLayer.toComp(barPath[1]);";
  const traceNullExpression = "var $bm_rt; $bm_rt = thisComp.layer('traceNull').effect('Trace Path')('Progress');";
  const animationData = {
    fr: 60,
    layers: [
      { ind: 1, nm: 'root-comp' },
      { ind: 2, nm: 'botDot' },
    ],
    assets: [{
      id: 'comp_inner',
      layers: [
        {
          ind: 1,
          nm: 'traceNull',
          ef: [{
            nm: 'Trace Path',
            ef: [{ nm: 'Progress', v: { a: 0, k: 42 } }],
          }],
          ks: {
            a: { a: 0, k: [0, 0, 0] },
            p: { a: 0, k: [15, 25, 0] },
            s: { a: 0, k: [100, 100, 100] },
            r: { a: 0, k: 0 },
          },
        },
        {
          ind: 2,
          nm: 'botDot',
          ks: {
            p: { a: 0, k: [0, 0, 0], x: barLookupExpression },
          },
        },
        {
          ind: 4,
          nm: 'bar',
          ks: {
            a: { a: 0, k: [0, 0, 0] },
            p: { a: 0, k: [10, 20, 0] },
            s: { a: 0, k: [100, 100, 100] },
            r: { a: 0, k: 0 },
          },
          shapes: [{
            ty: 'gr',
            nm: 'Group 1',
            it: [{
              ty: 'sh',
              nm: 'Path 1',
              ks: {
                a: 0,
                k: {
                  v: [[0, 0], [100, 0]],
                  i: [[0, 0], [0, 0]],
                  o: [[0, 0], [0, 0]],
                  c: false,
                },
              },
            }],
          }],
        },
        {
          ind: 5,
          nm: 'probe',
          shapes: [{
            ty: 'el',
            p: { a: 0, k: [0, 0] },
            s: { a: 0, k: [10, 10], x: traceNullExpression },
          }],
        },
      ],
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  const point = host.evaluateVec(barLookupExpression, 0, 2, [0, 0, 0]);
  const progress = host.evaluateDouble(traceNullExpression, 0, 5, 0);

  assert.deepEqual(point, [110, 20, 0]);
  assert.equal(progress, 42);
});

test('default expression host does not fall back to a wrong comp when expression context is missing', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.mjs'));
  const matchedExpression = "var $bm_rt; $bm_rt = thisLayer.name === 'inner-layer' ? 1 : -1;";

  const animationData = {
    fr: 60,
    layers: [
      { ind: 1, nm: 'root-layer' },
    ],
    assets: [{
      id: 'comp_inner',
      layers: [
        {
          ind: 1,
          nm: 'inner-layer',
          ks: {
            o: { a: 0, k: 100, x: matchedExpression },
          },
        },
      ],
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  const matched = host.evaluateDouble(matchedExpression, 0, 1, 99);
  const result = host.evaluateDouble('var $bm_rt; $bm_rt = thisLayer.index;', 0, 1, 99);

  assert.equal(matched, 1);
  assert.equal(result, 0);
});
