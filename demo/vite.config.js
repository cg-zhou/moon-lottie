import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@moon-lottie/browser-player': path.resolve(__dirname, '../packages/browser-player/src/index.js'),
      '@moon-lottie/react': path.resolve(__dirname, '../packages/react/src/index.js'),
      '@moon-lottie/web-component': path.resolve(__dirname, '../packages/web-component/src/index.js'),
    },
  },
})
