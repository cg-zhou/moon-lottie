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

  assert.match(html, /<script src="\.\/lottie\.min\.js"><\/script>/);
  assert.ok(fs.existsSync(path.join(repoRoot, 'demo', 'lottie.min.js')));
});

test('expression detection finds string-valued expression fields', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const helper = await import(path.join(repoRoot, 'demo', 'render_mode.js'));

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
  const helper = await import(path.join(repoRoot, 'demo', 'render_mode.js'));

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

test('canvas DPR helper scales backing store dimensions', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const helper = await import(path.join(repoRoot, 'demo', 'canvas_dpr.js'));
  const canvas = { width: 0, height: 0 };

  assert.deepEqual(helper.getCanvasPixelSize(80, 100, 2), {
    cssWidth: 80,
    cssHeight: 100,
    dpr: 2,
    pixelWidth: 160,
    pixelHeight: 200,
  });

  assert.deepEqual(helper.getCanvasPixelSize(80, 100, 0), {
    cssWidth: 80,
    cssHeight: 100,
    dpr: 1,
    pixelWidth: 80,
    pixelHeight: 100,
  });

  assert.deepEqual(helper.resizeCanvasForDpr(canvas, 80, 100, 1.5), {
    cssWidth: 80,
    cssHeight: 100,
    dpr: 1.5,
    pixelWidth: 120,
    pixelHeight: 150,
  });
  assert.equal(canvas.width, 120);
  assert.equal(canvas.height, 150);
});

test('canvas DPR helper applies scaled transform matrices', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const helper = await import(path.join(repoRoot, 'demo', 'canvas_dpr.js'));

  let lastTransform = null;
  helper.applyDprTransform({
    setTransform: (...args) => {
      lastTransform = args;
    },
  }, 1, 0, 0, 1, 12, 24, 2.5);

  assert.deepEqual(lastTransform, [2.5, 0, 0, 2.5, 30, 60]);
});

test('default expression host evaluates scalar expressions with layer effects context', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

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
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => ({ fr: 30, layers: [{ ind: 2 }] }),
    getPlaybackMeta: () => ({ fps: 30 }),
  });

  const value = host.evaluateVec('var $bm_rt; $bm_rt = sum(value, [5, -5, 0]);', 12, 2, [10, 20, 0]);

  assert.deepEqual(value, [15, 15, 0]);
});

test('default expression host supports createPath-style path mutations', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

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
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

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
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

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

test('default expression host matches lottie-web velocityAtTime sampling at key boundaries', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

  const animationData = {
    fr: 30,
    layers: [{
      ind: 1,
      ks: {
        p: {
          a: 1,
          k: [
            { t: 0, s: [0, 0, 0], e: [60, 0, 0] },
            { t: 30, s: [60, 0, 0], e: [60, 60, 0] },
            { t: 60, s: [60, 60, 0] },
          ],
          x: 'var $bm_rt; $bm_rt = velocityAtTime(1);',
        },
      },
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 30 }),
  });

  const value = host.evaluateVec('var $bm_rt; $bm_rt = velocityAtTime(1);', 30, 1, [0, 0, 0]);

  assert.deepEqual(value.map((component) => Math.round(component * 1000) / 1000), [60, 0, 0]);
});

test('default expression host matches lottie-web pointOnPath and tangentOnPath geometry', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

  const animationData = {
    fr: 30,
    layers: [
      {
        ind: 1,
        nm: 'wire',
        ty: 4,
        ks: {
          p: { a: 0, k: [10, 20, 0] },
          a: { a: 0, k: [0, 0, 0] },
          s: { a: 0, k: [100, 100, 100] },
          r: { a: 0, k: 15 },
          o: { a: 0, k: 100 },
        },
        shapes: [{
          ty: 'gr',
          nm: 'Shape 1',
          it: [
            {
              ty: 'sh',
              nm: 'Path 1',
              ks: {
                a: 0,
                k: {
                  v: [[0, 0], [100, 100]],
                  i: [[0, 0], [-50, 0]],
                  o: [[50, 0], [0, 0]],
                  c: false,
                },
              },
            },
            {
              ty: 'tr',
              p: { a: 0, k: [0, 0] },
              a: { a: 0, k: [0, 0] },
              s: { a: 0, k: [100, 100] },
              r: { a: 0, k: 0 },
              o: { a: 0, k: 100 },
              sk: { a: 0, k: 0 },
              sa: { a: 0, k: 0 },
              nm: 'Transform',
            },
          ],
        }],
      },
      {
        ind: 2,
        nm: 'mover',
        ty: 3,
        ef: [{
          nm: 'Trace Path',
          ef: [{ mn: 'Pseudo/ADBE Trace Path-0001', v: { a: 0, k: 35 } }],
        }],
        ks: {
          p: {
            a: 0,
            k: [0, 0, 0],
            x: "var $bm_rt; var pathLayer = thisComp.layer('wire'); var progress = div(thisLayer.effect('Trace Path')('Pseudo/ADBE Trace Path-0001'), 100); var pathToTrace = pathLayer('ADBE Root Vectors Group')(1)('ADBE Vectors Group')(1)('ADBE Vector Shape'); $bm_rt = pathLayer.toComp(pathToTrace.pointOnPath(progress));",
          },
          r: {
            a: 0,
            k: 0,
            x: "var $bm_rt; var pathToTrace = thisComp.layer('wire')('ADBE Root Vectors Group')(1)('ADBE Vectors Group')(1)('ADBE Vector Shape'); var progress = div(thisLayer.effect('Trace Path')('Pseudo/ADBE Trace Path-0001'), 100); var pathTan = pathToTrace.tangentOnPath(progress); $bm_rt = radiansToDegrees(Math.atan2(pathTan[1], pathTan[0]));",
          },
          a: { a: 0, k: [0, 0, 0] },
          s: { a: 0, k: [100, 100, 100] },
          o: { a: 0, k: 100 },
        },
      },
    ],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 30 }),
  });

  const point = host.evaluateVec(animationData.layers[1].ks.p.x, 0, 2, [0, 0, 0]);
  const rotation = host.evaluateDouble(animationData.layers[1].ks.r.x, 0, 2, 0);

  assert.deepEqual(
    point.map((component) => Math.round(component * 1000) / 1000),
    [40.422, 59.361, 0],
  );
  assert.equal(Math.round(rotation * 1000) / 1000, 59.826);
});

test('default expression host matches lottie-web path sampling for expression-mutated wire paths', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));
  const animationData = JSON.parse(
    fs.readFileSync(path.join(repoRoot, 'samples', '3_1_lights(expr).json'), 'utf8'),
  );

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: animationData.fr }),
  });

  const point = host.evaluateVec(
    "var $bm_rt; var pathLayer = thisComp.layer('wire'); var pathToTrace = pathLayer('ADBE Root Vectors Group')(1)('ADBE Vectors Group')(1)('ADBE Vector Shape'); $bm_rt = pathToTrace.pointOnPath(0.24);",
    113,
    8,
    [0, 0, 0],
  );
  const tangent = host.evaluateVec(
    "var $bm_rt; var pathToTrace = thisComp.layer('wire')('ADBE Root Vectors Group')(1)('ADBE Vectors Group')(1)('ADBE Vector Shape'); $bm_rt = pathToTrace.tangentOnPath(0.24);",
    113,
    8,
    [0, 0, 0],
  );

  assert.deepEqual(
    point.map((component) => Math.round(component * 1000) / 1000),
    [-151.562, 67.571],
  );
  assert.deepEqual(
    tangent.map((component) => Math.round(component * 1000000) / 1000000),
    [0.936634, 0.35031],
  );
});

test('default expression host resolves content path lookup and toComp projection', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

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
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

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
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

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
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

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
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

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
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

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
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));
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

test('default expression host uses explicit comp scope for nested thisComp.layer effect lookups', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

  const expression = "var $bm_rt; $bm_rt = thisComp.layer('traceNull').effect('Trace Path')('Progress');";
  const animationData = {
    fr: 60,
    layers: [
      { ind: 1, nm: 'grow graph' },
      { ind: 4, nm: 'grow graph' },
    ],
    assets: [{
      id: 'comp_79',
      layers: [
        {
          ind: 1,
          nm: 'traceNull',
          ef: [{
            nm: 'Trace Path',
            mn: 'Pseudo/ADBE Trace Path',
            ef: [{ nm: 'Progress', v: { a: 0, k: 42 } }],
          }],
        },
        {
          ind: 4,
          nm: 'bar',
          shapes: [{
            ty: 'tm',
            s: { a: 0, k: 0, x: expression },
          }],
        },
      ],
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  const result = host.evaluateDouble(expression, 0, 4, 'comp_79', 0);

  assert.equal(result, 42);
});

test('default expression host exposes evaluated transform.position for referenced layers', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

  const expression = "var $bm_rt; $bm_rt = thisComp.layer('traceNull').transform.position;";
  const traceExpression = "var $bm_rt; $bm_rt = [11, 22, 0];";
  const animationData = {
    fr: 60,
    layers: [{
      ind: 1,
      nm: 'traceNull',
      ks: {
        p: { a: 0, k: [590, -42, 0], x: traceExpression },
        a: { a: 0, k: [0, 0, 0] },
        s: { a: 0, k: [100, 100, 100] },
        r: { a: 0, k: 0 },
        o: { a: 0, k: 100 },
      },
    }, {
      ind: 2,
      nm: 'topDot',
      ks: {
        p: { a: 0, k: [20, 105, 0], x: expression },
      },
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  const result = host.evaluateVec(expression, 0, 2, [0, 0, 0]);

  assert.deepEqual(result, [11, 22, 0]);
});

test('default expression host resolves toComp parent matrices inside current precomp scope', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

  const expression = "var $bm_rt; $bm_rt = thisComp.layer('child').toComp([0, 0, 0]);";
  const animationData = {
    fr: 60,
    layers: [{
      ind: 1,
      nm: 'root-parent',
      ks: {
        p: { a: 0, k: [999, 999, 0] },
        a: { a: 0, k: [0, 0, 0] },
        s: { a: 0, k: [100, 100, 100] },
        r: { a: 0, k: 0 },
      },
    }],
    assets: [{
      id: 'comp_inner',
      layers: [{
        ind: 1,
        nm: 'parent',
        ks: {
          p: { a: 0, k: [10, 20, 0] },
          a: { a: 0, k: [0, 0, 0] },
          s: { a: 0, k: [100, 100, 100] },
          r: { a: 0, k: 0 },
        },
      }, {
        ind: 2,
        nm: 'child',
        parent: 1,
        ks: {
          p: { a: 0, k: [5, 7, 0] },
          a: { a: 0, k: [0, 0, 0] },
          s: { a: 0, k: [100, 100, 100] },
          r: { a: 0, k: 0 },
        },
      }],
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  const result = host.evaluateVec(expression, 0, 2, 'comp_inner', [0, 0, 0]);

  assert.deepEqual(result, [15, 27, 0]);
});

test('velocityAtTime returns pixels per second matching lottie-web units', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

  // Layer position goes from y=0 to y=60 over 60 frames (at 60fps = 1 second).
  // Velocity just before frame 60 should be ~60 px/s, NOT ~1 px/frame.
  const expression = `var $bm_rt;
    var n = 0;
    0 < numKeys && (n = nearestKey(time).index, key(n).time > time && n--);
    var t = n === 0 ? 0 : time - key(n).time;
    if (n > 0) {
      var v = velocityAtTime(sub(key(n).time, div(thisComp.frameDuration, 10)));
      $bm_rt = v;
    } else {
      $bm_rt = value;
    }`;

  const animationData = {
    fr: 60,
    layers: [{
      ind: 1,
      nm: 'bouncer',
      ks: {
        p: {
          a: 1,
          k: [
            { t: 0, s: [0, 0, 0], e: [0, 60, 0], o: { x: 1, y: 1 }, i: { x: 0, y: 0 } },
            { t: 60, s: [0, 60, 0], e: [0, 60, 0], o: { x: 0.167, y: 0.167 }, i: { x: 0.833, y: 0.833 } },
            { t: 120 },
          ],
          x: expression,
        },
      },
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  // Evaluate at frame 70 (after keyframe 60). n=1, t≈10/60s.
  // v = velocity at (key(1).time - frameDuration/10) = velocity near frame 59.9.
  // The easing used is close to linear (slope ≈ 1), so position y goes 0→60 over
  // 60 frames at 60fps and dY/dt ≈ 60 px/s.
  const result = host.evaluateVec(expression, 70, 1, [0, 0, 0]);
  // The y-component of the velocity should be close to 60 px/s (not 1 px/frame).
  assert.ok(Array.isArray(result), 'result should be an array');
  const vyApprox = result[1];
  assert.ok(
    Math.abs(vyApprox) > 10,
    `velocityAtTime y-component should be in px/s (~60), got ${vyApprox}`,
  );
});

test('shape path expression is evaluated when accessed from another layer', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

  // Wire layer has a path expression that shifts all vertices by +100 in y.
  const wirePathExpression = `var $bm_rt;
    var pts = thisProperty.points();
    var inT = thisProperty.inTangents();
    var outT = thisProperty.outTangents();
    for (var i = 0; i < pts.length; i++) { pts[i] = [pts[i][0], pts[i][1] + 100]; }
    $bm_rt = createPath(pts, inT, outT, false);`;

  // Light layer expression reads the wire's path and returns the midpoint on it.
  const lightExpression = `var $bm_rt;
    var wireLayer = thisComp.layer('wire');
    var path = wireLayer('ADBE Root Vectors Group')(1)('ADBE Vectors Group')(1)('ADBE Vector Shape');
    $bm_rt = wireLayer.toComp(path.pointOnPath(0.5));`;

  const animationData = {
    fr: 60,
    w: 800,
    h: 600,
    layers: [{
      ind: 1,
      nm: 'wire',
      ks: {
        p: { a: 0, k: [0, 0, 0] },
        a: { a: 0, k: [0, 0, 0] },
        s: { a: 0, k: [100, 100, 100] },
        r: { a: 0, k: 0 },
      },
      shapes: [{
        ty: 'gr',
        it: [{
          ty: 'sh',
          ks: {
            a: 0,
            k: { v: [[0, 0], [100, 0]], i: [[0, 0], [0, 0]], o: [[0, 0], [0, 0]], c: false },
            x: wirePathExpression,
          },
        }],
      }],
    }, {
      ind: 2,
      nm: 'light',
      ks: { p: { a: 0, k: [0, 0, 0], x: lightExpression } },
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  // The static wire path is at y=0. After the expression, all y values become +100.
  // The midpoint on path should be at approximately [50, 100] in wire-local space,
  // which after toComp([0,0] wire position) = [50, 100].
  const result = host.evaluateVec(lightExpression, 0, 2, [0, 0, 0]);
  assert.ok(Array.isArray(result), 'result should be an array');
  // Y should be ≈100 (expression-evaluated path), not 0 (static path).
  assert.ok(
    Math.abs(result[1] - 100) < 5,
    `Expected y ≈ 100 (expression path), got ${result[1]}`,
  );
});

test('toComp uses expression-evaluated position when accessing another layer', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

  // The null layer has a position expression that overrides to [500, 400].
  const nullPosExpression = "var $bm_rt; $bm_rt = [500, 400, 0];";
  // The wire path expression reads the null layer's position via toComp(anchorPoint).
  const wireExpression = `var $bm_rt;
    var nullLayer = thisComp.layer('movingNull');
    var pt = fromCompToSurface(nullLayer.toComp(nullLayer.anchorPoint));
    $bm_rt = createPath([pt, [200, 0]], [[0,0],[0,0]], [[0,0],[0,0]], false);`;

  const animationData = {
    fr: 60,
    w: 800,
    h: 600,
    layers: [{
      ind: 1,
      nm: 'movingNull',
      ks: {
        // Static base position [0, 0] — expression overrides to [500, 400].
        p: { a: 0, k: [0, 0, 0], x: nullPosExpression },
        a: { a: 0, k: [0, 0, 0] },
        s: { a: 0, k: [100, 100, 100] },
        r: { a: 0, k: 0 },
      },
    }, {
      ind: 2,
      nm: 'wire',
      ks: {
        p: { a: 0, k: [0, 0, 0] },
        a: { a: 0, k: [0, 0, 0] },
        s: { a: 0, k: [100, 100, 100] },
        r: { a: 0, k: 0 },
      },
      shapes: [{
        ty: 'gr',
        it: [{
          ty: 'sh',
          ks: {
            a: 0,
            k: { v: [[0, 0], [200, 0]], i: [[0, 0], [0, 0]], o: [[0, 0], [0, 0]], c: false },
            x: wireExpression,
          },
        }],
      }],
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  // The wire path expression builds from the null layer's expression-evaluated position
  // [500, 400].  fromCompToSurface for the wire layer at [0,0] = comp coords directly.
  // First vertex of wire path should be [500, 400].
  const rawPath = { v: [[0, 0], [200, 0]], i: [[0, 0], [0, 0]], o: [[0, 0], [0, 0]], c: false };
  const result = host.evaluatePath(wireExpression, 0, 2, rawPath);
  assert.ok(result && Array.isArray(result.vertices), 'result should be a path');
  const firstVertex = result.vertices[0];
  // If expression-evaluated position was used: [500, 400].  If static [0,0] was used: [0, 0].
  assert.ok(
    Math.abs(firstVertex[0] - 500) < 5 && Math.abs(firstVertex[1] - 400) < 5,
    `Expected first vertex ≈ [500, 400] (expression pos), got [${firstVertex}]`,
  );
});

test('default expression host evaluates loopOut expression on effect parameter (ripple animation fix)', async () => {
  // Regression test for 3_4_ripple(expr).json: after frame 90 of the root comp the
  // animation appeared frozen because createEffectAccessor called sampleKeyframedProperty
  // directly without evaluating the `x` expression on the effect parameter value.
  // The Progress slider has a loopOut('cycle') expression that must cycle the value
  // beyond the last keyframe instead of clamping.
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

  // Minimal reproduction of the ripple's traceNull layer:
  //   - layer ind=1 is a null layer with a "Trace Path" effect
  //   - The Progress parameter has keyframes 0→100 (frames 0-60) and 100→0 (frames 60-120)
  //   - A loopOut('cycle') expression makes it cycle beyond frame 120
  //   - A boolean "Loop" parameter (k=1) enables the loop
  const loopOutExpr = [
    'var $bm_rt;',
    "if (thisProperty.propertyGroup(1)('Pseudo/ADBE Trace Path-0002') == true && thisProperty.numKeys > 1) {",
    "    $bm_rt = thisProperty.loopOut('cycle');",
    '} else {',
    '    $bm_rt = value;',
    '}',
  ].join('\n');

  const animationData = {
    fr: 60,
    layers: [{
      ind: 1,
      nm: 'traceNull',
      ef: [{
        nm: 'Trace Path',
        mn: 'Pseudo/ADBE Trace Path',
        ef: [
          {
            mn: 'Pseudo/ADBE Trace Path-0001',
            nm: 'Progress',
            v: {
              a: 1,
              k: [
                { t: 0, s: [0], e: [100] },
                { t: 60, s: [100], e: [0] },
                { t: 120 },
              ],
              x: loopOutExpr,
            },
          },
          {
            mn: 'Pseudo/ADBE Trace Path-0002',
            nm: 'Loop',
            v: { a: 0, k: 1 },
          },
        ],
      }],
      ks: { p: { a: 0, k: [0, 0, 0] } },
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  // The expression that accesses the effect's Progress parameter (as used in the ripple animation)
  const accessExpr = "var $bm_rt; $bm_rt = thisLayer.effect('Trace Path')('Pseudo/ADBE Trace Path-0001');";

  // At frame 30 (within range): Progress = 50, no loopOut needed
  const at30 = host.evaluateDouble(accessExpr, 30, 1, 0);
  assert.ok(Math.abs(at30 - 50) < 2, `Expected ~50 at frame 30, got ${at30}`);

  // At frame 150 (beyond last keyframe 120 by 30 frames): loopOut('cycle') should sample
  // at frame 150-120=30, which is within the first half (0→100) giving ~50
  const at150 = host.evaluateDouble(accessExpr, 150, 1, 0);
  assert.ok(Math.abs(at150 - 50) < 2, `Expected ~50 at frame 150 (loopOut cycle), got ${at150}`);

  // At frame 180 (beyond last keyframe by 60 frames): samples at frame 60 → Progress = 100
  const at180 = host.evaluateDouble(accessExpr, 180, 1, 0);
  assert.ok(Math.abs(at180 - 100) < 2, `Expected ~100 at frame 180 (loopOut cycle), got ${at180}`);

  // Without the fix, frames > 120 would be clamped to the last keyframe value (0).
  // Verify the value is NOT frozen at 0 for frames beyond the keyframe range.
  assert.ok(at150 > 1, `loopOut should not return frozen value 0 at frame 150, got ${at150}`);
  assert.ok(at180 > 1, `loopOut should not return frozen value 0 at frame 180, got ${at180}`);
});

test('default expression host preserves keyframe easing for effect parameters with array tangents', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const hostModule = await import(path.join(repoRoot, 'demo', 'expression_host.js'));

  const solveCubicBezierEasing = (x1, y1, x2, y2, targetX) => {
    if (targetX <= 0) return 0;
    if (targetX >= 1) return 1;
    const cx = 3 * x1;
    const bx = 3 * (x2 - x1) - cx;
    const ax = 1 - cx - bx;
    const cy = 3 * y1;
    const by = 3 * (y2 - y1) - cy;
    const ay = 1 - cy - by;
    let t = targetX;
    for (let iteration = 0; iteration < 8; iteration += 1) {
      const x = ((ax * t + bx) * t + cx) * t - targetX;
      const dx = (3 * ax * t + 2 * bx) * t + cx;
      if (Math.abs(dx) < 1e-6) break;
      t -= x / dx;
    }
    return ((ay * t + by) * t + cy) * t;
  };

  const animationData = {
    fr: 60,
    layers: [{
      ind: 1,
      nm: 'traceNull',
      ef: [{
        nm: 'Trace Path',
        mn: 'Pseudo/ADBE Trace Path',
        ef: [{
          mn: 'Pseudo/ADBE Trace Path-0001',
          nm: 'Progress',
          v: {
            a: 1,
            k: [
              { t: 0, s: [0], e: [100], i: { x: [0.6], y: [1] }, o: { x: [0.4], y: [0] } },
              { t: 60, s: [100], e: [0], i: { x: [0.6], y: [1] }, o: { x: [0.4], y: [0] } },
              { t: 120 },
            ],
          },
        }],
      }],
      ks: { p: { a: 0, k: [0, 0, 0] } },
    }],
  };

  const host = hostModule.createDefaultExpressionHost({
    getAnimationData: () => animationData,
    getPlaybackMeta: () => ({ fps: 60 }),
  });

  const accessExpr = "var $bm_rt; $bm_rt = thisLayer.effect('Trace Path')('Pseudo/ADBE Trace Path-0001');";
  const at84 = host.evaluateDouble(accessExpr, 84, 1, 0);
  const at114 = host.evaluateDouble(accessExpr, 114, 1, 0);

  const expectedAt84 = 100 * (1 - solveCubicBezierEasing(0.4, 0, 0.6, 1, (84 - 60) / 60));
  const expectedAt114 = 100 * (1 - solveCubicBezierEasing(0.4, 0, 0.6, 1, (114 - 60) / 60));

  assert.ok(Math.abs(at84 - expectedAt84) < 0.5, `Expected eased value ~${expectedAt84} at frame 84, got ${at84}`);
  assert.ok(Math.abs(at114 - expectedAt114) < 0.5, `Expected eased value ~${expectedAt114} at frame 114, got ${at114}`);
  assert.ok(Math.abs(at84 - 60) > 3, `Expected frame 84 to be eased, not linear 60, got ${at84}`);
  assert.ok(Math.abs(at114 - 10) > 3, `Expected frame 114 to be eased, not linear 10, got ${at114}`);
});
