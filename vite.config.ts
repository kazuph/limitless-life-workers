import { cloudflare } from '@cloudflare/vite-plugin'
import { defineConfig, type Plugin } from 'vite'
import ssrPlugin from 'vite-ssr-components/plugin'
import { moonbit } from 'vite-plugin-moonbit'
import { fileURLToPath, URL } from 'node:url'

// Plugin to patch MoonBit's random_seed for Cloudflare Workers compatibility
// Cloudflare Workers don't allow crypto.getRandomValues in global scope
function patchMoonbitRandom(): Plugin {
  return {
    name: 'patch-moonbit-random',
    apply: 'build',
    transform(code, id) {
      if (id.includes('moonbit') || id.includes('main.js') || id.includes('client.js')) {
        // Replace the immediate random seed call with a lazy initialization
        // Original: const ...$$seed = ...$$random_seed();
        // Patched: const ...$$seed = 0; (defer actual initialization)
        return code.replace(
          /const\s+(moonbitlang\$core\$builtin\$\$seed)\s*=\s*moonbitlang\$core\$builtin\$\$random_seed\(\);/g,
          'const $1 = 0; // Patched for CF Workers'
        )
      }
      return code
    },
    generateBundle(_, bundle) {
      // Also patch in the final bundle
      for (const fileName of Object.keys(bundle)) {
        const chunk = bundle[fileName]
        if (chunk.type === 'chunk' && chunk.code) {
          chunk.code = chunk.code.replace(
            /const\s+(moonbitlang\$core\$builtin\$\$seed)\s*=\s*moonbitlang\$core\$builtin\$\$random_seed\(\);/g,
            'const $1 = 0; // Patched for CF Workers'
          )
        }
      }
    }
  }
}

export default defineConfig(({ mode, isSsrBuild }) => ({
  appType: 'custom',
  plugins: [
    cloudflare(),
    ssrPlugin(),
    patchMoonbitRandom(),
    moonbit({
      target: 'js',
      watch: mode === 'development',
    }),
  ],
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
    manifest: true,
    rollupOptions: {
      input: isSsrBuild ? './src/index.tsx' : './src/client/main.ts',
      output: !isSsrBuild ? {
        entryFileNames: 'assets/main.js',
        chunkFileNames: 'assets/[name]-[hash].js',
        assetFileNames: (assetInfo) => {
          // Fixed filename for main CSS
          if (assetInfo.name === 'main.css' || assetInfo.name?.endsWith('main.css')) {
            return 'assets/main.css'
          }
          return 'assets/[name]-[hash][extname]'
        }
      } : undefined
    }
  }
}))
