import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@moon-lottie/core': path.resolve(__dirname, '../packages/moon-lottie/src/index.js'),
      '@moon-lottie/react': path.resolve(__dirname, '../packages/moon-lottie-react/src/index.js'),
    },
  },
})
