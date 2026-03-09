const test = require('node:test');
const assert = require('node:assert/strict');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

const helperUrl = pathToFileURL(
  path.resolve(__dirname, '../../demo/moon_string.js')
).href;

test('moonStringJS returns native JS strings unchanged', async () => {
  const { moonStringJS } = await import(helperUrl);
  assert.equal(moonStringJS('image_0'), 'image_0');
  assert.equal(moonStringJS(''), '');
  assert.equal(moonStringJS(null), '');
  assert.equal(moonStringJS(undefined), '');
});

test('moonStringJS decodes WasmGC-style objects via valueOf/toString before array fallback', async () => {
  const { moonStringJS } = await import(helperUrl);

  assert.equal(
    moonStringJS({ valueOf: () => 'image_7' }),
    'image_7'
  );

  assert.equal(
    moonStringJS({ toString: () => '5.1.18' }),
    '5.1.18'
  );
});

test('moonStringJS still supports array-like char code objects', async () => {
  const { moonStringJS } = await import(helperUrl);
  const arrayLike = {
    length: 7,
    0: 105,
    1: 109,
    2: 97,
    3: 103,
    4: 101,
    5: 95,
    6: 49,
  };
  assert.equal(moonStringJS(arrayLike), 'image_1');
});

test('readWasmString reconstructs exported wasm strings from len/char callbacks', async () => {
  const { readWasmString } = await import(helperUrl);
  const text = '5.1.18';
  assert.equal(
    readWasmString(text.length, (idx) => text.charCodeAt(idx)),
    text
  );
});

test('readWasmString returns empty string for empty or invalid exported values', async () => {
  const { readWasmString } = await import(helperUrl);
  assert.equal(readWasmString(0, () => 0), '');
  assert.equal(readWasmString(-1, () => 0), '');
  assert.equal(readWasmString(3, () => undefined), '');
  assert.equal(readWasmString(3, () => -1), '');
});

test('readWasmString does not invoke callback when exported length is negative', async () => {
  const { readWasmString } = await import(helperUrl);
  let called = false;
  assert.equal(readWasmString(-1, () => {
    called = true;
    return 65;
  }), '');
  assert.equal(called, false);
});
