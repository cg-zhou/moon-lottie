import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'

export default defineConfig({
  base: './',
  resolve: {
    alias: {
      '@moon-lottie/core': fileURLToPath(new URL('../../moon-lottie/src/index.js', import.meta.url)),
    },
  },
})