const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

const helperUrl = pathToFileURL(
  path.resolve(__dirname, '../../demo/image_ref_queue.js')
).href;

test('collectImageRefsForFrame matches reverse render order and matte exit order', async () => {
  const { collectImageRefsForFrame } = await import(helperUrl);
  for (const matteType of [1, 2, 3, 4]) {
    const animation = {
      layers: [
        { ty: 2, refId: 'matte', ind: 1, td: 1, ip: 0, op: 10, st: 0 },
        { ty: 2, refId: 'target', ind: 2, tt: matteType, ip: 0, op: 10, st: 0 },
        { ty: 2, refId: 'front', ind: 3, ip: 0, op: 10, st: 0 },
      ],
      assets: [],
    };

    assert.deepEqual(
      collectImageRefsForFrame(animation, 0),
      ['front', 'target', 'matte'],
      `tt=${matteType} should preserve target-then-matte order`
    );
  }
});

test('collectImageRefsForFrame recurses through precomps using layer-local frame', async () => {
  const { collectImageRefsForFrame } = await import(helperUrl);
  const animation = {
    layers: [
      { ty: 0, refId: 'comp_1', ind: 1, ip: 0, op: 20, st: 5 },
    ],
    assets: [
      {
        id: 'comp_1',
        layers: [
          { ty: 2, refId: 'late', ind: 1, ip: 3, op: 10, st: 0 },
          { ty: 2, refId: 'early', ind: 2, ip: 0, op: 10, st: 0 },
        ],
      },
    ],
  };

  assert.deepEqual(collectImageRefsForFrame(animation, 5), ['early']);
  assert.deepEqual(collectImageRefsForFrame(animation, 8), ['early', 'late']);
});

test('collectImageRefsForFrame ignores non-matte previous layers for matte recursion', async () => {
  const { collectImageRefsForFrame } = await import(helperUrl);
  const animation = {
    layers: [
      { ty: 2, refId: 'plain', ind: 1, ip: 0, op: 10, st: 0 },
      { ty: 2, refId: 'target', ind: 2, tt: 1, ip: 0, op: 10, st: 0 },
    ],
    assets: [],
  };

  assert.deepEqual(collectImageRefsForFrame(animation, 0), ['target', 'plain']);
});
