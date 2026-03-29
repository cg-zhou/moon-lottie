const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

test('public sample index entries resolve to existing sample files', () => {
  const repoRoot = path.resolve(__dirname, '..');
  const sampleIndex = JSON.parse(
    fs.readFileSync(path.join(repoRoot, 'demo', 'public', 'sample_index.json'), 'utf8'),
  );
  const missingEntries = sampleIndex
    .map((entry) => entry.file)
    .filter((file, index, files) => files.indexOf(file) === index)
    .filter((file) => !fs.existsSync(path.join(repoRoot, 'samples', file)));

  assert.deepEqual(missingEntries, []);
});
