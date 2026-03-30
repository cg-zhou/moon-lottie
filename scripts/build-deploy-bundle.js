import { cpSync, existsSync, mkdirSync, rmSync, writeFileSync } from 'node:fs'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const currentDir = dirname(fileURLToPath(import.meta.url))
const repoRoot = resolve(currentDir, '..')
const outputDir = resolve(repoRoot, 'deploy-dist')
const siteDistDir = resolve(repoRoot, 'demo', 'dist')
const exampleDistDirs = [
  {
    id: 'moon-lottie-core',
    distDir: resolve(repoRoot, 'packages', 'examples', 'moon-lottie-core', 'dist'),
  },
  {
    id: 'moon-lottie-react',
    distDir: resolve(repoRoot, 'packages', 'examples', 'moon-lottie-react', 'dist'),
  },
]

function assertExists(path, label) {
  if (!existsSync(path)) {
    throw new Error(`Missing ${label}: ${path}`)
  }
}

assertExists(siteDistDir, 'site build output')
for (const example of exampleDistDirs) {
  assertExists(example.distDir, `example build output for ${example.id}`)
}

rmSync(outputDir, { recursive: true, force: true })
mkdirSync(outputDir, { recursive: true })

cpSync(siteDistDir, outputDir, { recursive: true })

const examplesRoot = resolve(outputDir, 'examples')
mkdirSync(examplesRoot, { recursive: true })

for (const example of exampleDistDirs) {
  cpSync(example.distDir, resolve(examplesRoot, example.id), { recursive: true })
}

writeFileSync(resolve(outputDir, '.nojekyll'), '')

console.log(`Built unified deploy bundle at ${outputDir}`)