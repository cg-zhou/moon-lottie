import { copyFileSync, existsSync, mkdirSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const currentDir = dirname(fileURLToPath(import.meta.url))
const projectRoot = resolve(currentDir, '..')

const files = [
  ['../../../samples/1_1_Super_Mario.json', 'public/samples/1_1_Super_Mario.json'],
  ['node_modules/@moon-lottie/core/runtime/moon-lottie-runtime.wasm', 'public/runtime/wasm/moon-lottie-runtime.wasm'],
  ['node_modules/@moon-lottie/core/runtime/moon-lottie-runtime.js', 'public/runtime/js/moon-lottie-runtime.js'],
]

for (const [sourceRelativePath, targetRelativePath] of files) {
  const sourcePath = resolve(projectRoot, sourceRelativePath)
  const targetPath = resolve(projectRoot, targetRelativePath)

  if (!existsSync(sourcePath)) {
    throw new Error(`Missing demo asset: ${sourceRelativePath}`)
  }

  mkdirSync(dirname(targetPath), { recursive: true })
  copyFileSync(sourcePath, targetPath)
}

console.log('Synced demo assets and runtime to public/')