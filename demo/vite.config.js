import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  define: {
    __MOON_LOTTIE_BUILD_TIME__: JSON.stringify(Date.now().toString()),
  },
  build: {
    rollupOptions: {
      input: {
        main: fileURLToPath(new URL('./index.html', import.meta.url)),
        preview: fileURLToPath(new URL('./preview.html', import.meta.url)),
      },
    },
  },
  resolve: {
    alias: {
      '@moon-lottie/core': path.resolve(__dirname, '../packages/moon-lottie/src/index.js'),
      '@moon-lottie/react': path.resolve(__dirname, '../packages/moon-lottie-react/src/index.js'),
    },
  },
})
