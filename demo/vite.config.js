import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'
import { createRequire } from 'module'

const require = createRequire(import.meta.url)
const corePkg = require('../packages/moon-lottie/package.json')

export default defineConfig({
  plugins: [react()],
  define: {
    __MOON_LOTTIE_RUNTIME_VERSION__: JSON.stringify(corePkg.version),
  },
  resolve: {
    alias: {
      '@moon-lottie/core': path.resolve(__dirname, '../packages/moon-lottie/src/index.js'),
      '@moon-lottie/react': path.resolve(__dirname, '../packages/moon-lottie-react/src/index.js'),
    },
  },
})
