import { copyFileSync, existsSync, mkdirSync } from 'node:fs'
import { createRequire } from 'node:module'
import { dirname, isAbsolute, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const currentDir = dirname(fileURLToPath(import.meta.url))
const projectRoot = resolve(currentDir, '..')
const require = createRequire(import.meta.url)
const coreEntryPath = require.resolve('@moon-lottie/core')
const corePackageRoot = resolve(dirname(coreEntryPath), '..')

const files = [
  ['../../../samples/1_1_Super_Mario.json', 'public/samples/1_1_Super_Mario.json'],
  [resolve(corePackageRoot, 'runtime/moon-lottie-runtime.wasm'), 'public/runtime/wasm/moon-lottie-runtime.wasm'],
  [resolve(corePackageRoot, 'runtime/moon-lottie-runtime.js'), 'public/runtime/js/moon-lottie-runtime.js'],
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
