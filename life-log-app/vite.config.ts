import { cloudflare } from '@cloudflare/vite-plugin'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'
import ssrPlugin from 'vite-ssr-components/plugin'
import { fileURLToPath, URL } from 'node:url'

export default defineConfig({
  appType: 'custom',
  plugins: [cloudflare(), ssrPlugin(), react()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  server: {
    port: 5174,
    strictPort: true
  },
  build: {
    rollupOptions: {
      input: './src/index.tsx'
    }
  }
})
