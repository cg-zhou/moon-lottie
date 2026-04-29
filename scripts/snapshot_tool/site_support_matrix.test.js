const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

function importRepoModule(repoRoot, ...segments) {
  return import(pathToFileURL(path.join(repoRoot, ...segments)).href);
}

test('site does not present markers as a supported Moon feature example', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const { supportSections } = await importRepoModule(repoRoot, 'demo', 'src', 'supportMatrix.js');
  const { featureExampleMap } = await importRepoModule(repoRoot, 'demo', 'src', 'featureExamples.js');

  const otherSection = supportSections.find(section => section.id === 'other');
  assert.ok(otherSection);

  const markerRow = otherSection.rows.find(row => row.feature === '标记');
  assert.equal(markerRow?.moon?.status, 'unsupported');
  assert.match(markerRow?.moon?.detail ?? '', /markers/);
  assert.equal(featureExampleMap.other?.['标记'], undefined);
});

test('audited feature demos use section-specific animations instead of unrelated shared placeholders', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const { featureExampleMap } = await importRepoModule(repoRoot, 'demo', 'src', 'featureExamples.js');

  const exactMatches = {
    strokes: {
      '渐变': 'stroke-gradient',
    },
    transforms: {
      '位置（分离 X/Y）': 'transform-separated-position',
      '父子层级': 'transform-parent-hierarchy',
    },
    layerEffects: {
      '填充': 'layer-fill-effect',
    },
    other: {
      '预合成': 'other-precomp',
      '时间重映射': 'other-time-remap',
    },
  };

  for (const [sectionId, features] of Object.entries(exactMatches)) {
    for (const [feature, expectedName] of Object.entries(features)) {
      assert.equal(featureExampleMap[sectionId]?.[feature]?.animationData?.nm, expectedName);
    }
  }

  const prefixMatches = {
    interpolation: 'interp-',
    masks: 'mask-',
    mattes: 'matte-',
    text: 'text-',
  };

  for (const [sectionId, prefix] of Object.entries(prefixMatches)) {
    for (const [feature, example] of Object.entries(featureExampleMap[sectionId] ?? {})) {
      assert.ok(
        example.animationData?.nm?.startsWith(prefix),
        `${sectionId}.${feature} should use an animation starting with ${prefix}, got ${example.animationData?.nm}`,
      );
    }
  }
});

test('support page demo regressions preserve audited example alignment and text safety', async () => {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const { featureExampleMap } = await importRepoModule(repoRoot, 'demo', 'src', 'featureExamples.js');

  const anchorExample = featureExampleMap.transforms['锚点']?.animationData;
  assert.ok(anchorExample);
  assert.deepEqual(anchorExample.layers[0]?.ks?.p?.k, anchorExample.layers[1]?.ks?.p?.k);

  const precompExample = featureExampleMap.other['预合成']?.animationData;
  const precompLayer = precompExample?.layers?.[0];
  const precompAsset = precompExample?.assets?.[0];
  assert.deepEqual(precompLayer?.ks?.a?.k, [120, 90, 0]);
  assert.equal(precompAsset?.w, 240);
  assert.equal(precompAsset?.h, 180);

  const timeRemapExample = featureExampleMap.other['时间重映射']?.animationData;
  const timeRemapLayer = timeRemapExample?.layers?.[0];
  const timeRemapAsset = timeRemapExample?.assets?.[0];
  assert.deepEqual(timeRemapLayer?.ks?.a?.k, [120, 90, 0]);
  assert.equal(timeRemapAsset?.w, 240);
  assert.equal(timeRemapAsset?.h, 180);

  const fontExample = featureExampleMap.text['字体']?.animationData;
  assert.equal(fontExample?.layers?.[0]?.t?.d?.k?.[0]?.s?.t, 'Moon');

  for (const [feature, example] of Object.entries(featureExampleMap.text ?? {})) {
    const animationData = example?.animationData;
    const supportedGlyphs = new Set((animationData?.chars ?? []).map((char) => char.ch));
    for (const layer of animationData?.layers ?? []) {
      if (layer?.ty !== 5) {
        continue;
      }
      const text = layer?.t?.d?.k?.[0]?.s?.t ?? '';
      for (const char of text.replace(/\s+/g, '')) {
        assert.ok(
          supportedGlyphs.size === 0 || supportedGlyphs.has(char),
          `text.${feature} uses unsupported demo glyph "${char}"`,
        );
      }
    }
  }
});
