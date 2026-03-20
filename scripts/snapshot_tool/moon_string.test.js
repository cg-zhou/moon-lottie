const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const wasmCompileOptions = { builtins: ['js-string'] };
const wasmJsStringImportModule = 'wasm:js-string';

function ensureWasmBuilt(repoRoot) {
  const wasmPath = path.join(repoRoot, '_build/wasm-gc/debug/build/cmd/player_runtime/player_runtime.wasm');
  if (fs.existsSync(wasmPath)) return;

  const result = spawnSync('moon', ['build', '--target', 'wasm-gc'], {
    cwd: repoRoot,
    stdio: 'inherit',
  });
  if (result.status !== 0) {
    throw new Error('Failed to build wasm target with moon build --target wasm-gc');
  }
}

function createBaseImports(currentJsonStr) {
  const noop = () => {};
  return {
    _: new Proxy({}, { get: (_, name) => typeof name === 'string' ? name : undefined }),
    demo: {
      get_json_string: () => currentJsonStr,
      log_frame: noop,
    },
    spectest: { print_char: noop },
    canvas: new Proxy({}, { get: () => noop }),
    expressions: new Proxy({}, { get: () => noop }),
    'moonbit:ffi': {
      make_closure: (funcref, closure) => funcref.bind(null, closure),
    },
  };
}

test('wasm-gc demo passes strings directly between JS and MoonBit', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  ensureWasmBuilt(repoRoot);

  const wasmPath = path.join(repoRoot, '_build/wasm-gc/debug/build/cmd/player_runtime/player_runtime.wasm');
  const jsonPath = path.join(repoRoot, 'samples', '1_1_Super_Mario.json');
  const currentJsonStr = fs.readFileSync(jsonPath, 'utf8');
  const wasmBuffer = fs.readFileSync(wasmPath);

  const module = await WebAssembly.compile(wasmBuffer, wasmCompileOptions);
  const instance = await WebAssembly.instantiate(module, createBaseImports(currentJsonStr), wasmCompileOptions);

  const exports = instance.exports;
  const player = exports.create_player_from_js();
  assert.ok(player);

  const version = exports.get_version(player);
  assert.equal(typeof version, 'string');
  assert.ok(version.length > 0);
  assert.equal(version, '5.7.0');
});

test('wasm-gc build imports the wasm:js-string builtin module name', async () => {
  const repoRoot = path.resolve(__dirname, '../..');
  ensureWasmBuilt(repoRoot);

  const wasmPath = path.join(repoRoot, '_build/wasm-gc/debug/build/cmd/player_runtime/player_runtime.wasm');
  const wasmBuffer = fs.readFileSync(wasmPath);

  const module = await WebAssembly.compile(wasmBuffer);
  const imports = WebAssembly.Module.imports(module);
  assert.ok(imports.some((entry) => entry.module === wasmJsStringImportModule));
});
