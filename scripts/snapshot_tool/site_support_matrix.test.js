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

  const generalSection = supportSections.find(section => section.id === 'general');
  assert.ok(generalSection);

  const markerRow = generalSection.rows.find(row => row.feature === '标记');
  assert.deepEqual(markerRow?.moon, {
    status: 'unknown',
    symbol: '❔',
    detail: 'Animation 模型已预留 markers 字段，但当前解析器尚未读取 markers',
  });
  assert.equal(featureExampleMap.general?.['标记'], undefined);
});
