import { copyFileSync, existsSync, mkdirSync } from 'node:fs'
import { createRequire } from 'node:module'
import { dirname, isAbsolute, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const currentDir = dirname(fileURLToPath(import.meta.url))
const projectRoot = resolve(currentDir, '..')
const repoRoot = resolve(projectRoot, '../../..')
const localCorePackageRoot = resolve(projectRoot, '../../moon-lottie')

let corePackageRoot = localCorePackageRoot
try {
  const require = createRequire(import.meta.url)
  const coreEntryPath = require.resolve('@moon-lottie/core')
  corePackageRoot = resolve(dirname(coreEntryPath), '..')
} catch {
  console.warn('Falling back to local packages/moon-lottie for core assets')
}

function pickExistingPath(candidates, label) {
  const sourcePath = candidates.find((candidate) => existsSync(candidate))
  if (!sourcePath) {
    throw new Error(`Missing demo asset for ${label}: ${candidates.join(', ')}`)
  }
  return sourcePath
}

const files = [
  [resolve(projectRoot, '../../../samples/1_1_Super_Mario.json'), 'public/samples/1_1_Super_Mario.json'],
  [
    pickExistingPath([
      resolve(corePackageRoot, 'runtime/moon-lottie-runtime.wasm'),
      resolve(repoRoot, '_build/wasm-gc/release/build/cmd/player_runtime/player_runtime.wasm'),
      resolve(repoRoot, '_build/wasm-gc/debug/build/cmd/player_runtime/player_runtime.wasm'),
    ], 'moon-lottie-runtime.wasm'),
    'public/runtime/wasm/moon-lottie-runtime.wasm',
  ],
  [
    pickExistingPath([
      resolve(corePackageRoot, 'runtime/moon-lottie-runtime.js'),
      resolve(repoRoot, '_build/js/release/build/cmd/player_runtime/player_runtime.js'),
      resolve(repoRoot, '_build/js/debug/build/cmd/player_runtime/player_runtime.js'),
    ], 'moon-lottie-runtime.js'),
    'public/runtime/js/moon-lottie-runtime.js',
  ],
]

for (const [sourceRelativePath, targetRelativePath] of files) {
  const sourcePath = isAbsolute(sourceRelativePath) ? sourceRelativePath : resolve(projectRoot, sourceRelativePath)
  const targetPath = resolve(projectRoot, targetRelativePath)

  if (!existsSync(sourcePath)) {
    throw new Error(`Missing demo asset: ${sourceRelativePath}`)
  }

  mkdirSync(dirname(targetPath), { recursive: true })
  copyFileSync(sourcePath, targetPath)
}

console.log('Synced demo assets and runtime to public/')
