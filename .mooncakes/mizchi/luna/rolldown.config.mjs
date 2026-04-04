import { defineConfig } from 'rolldown';

export default defineConfig([
  // ESM build with code splitting
  {
    input: {
      'loader': './js/loader/src/loader.ts',
      'wc-loader': './js/loader/src/wc-loader.ts',
      'sol-nav': './js/loader/src/sol-nav.ts',
      'lib': './js/loader/src/lib.ts',
      // Boot runtime (chunk loader + minimal router)
      'boot/index': './js/loader/src/boot/index.ts',
      'boot/loader': './js/loader/src/boot/loader.ts',
      'boot/router': './js/loader/src/boot/router.ts',
      // Extended routers (Phase 7)
      'router/index': './js/loader/src/router/index.ts',
      'router/hybrid': './js/loader/src/router/hybrid.ts',
      'router/spa': './js/loader/src/router/spa.ts',
      'router/scroll': './js/loader/src/router/scroll.ts',
    },
    output: {
      dir: './js/loader/dist',
      format: 'esm',
      entryFileNames: '[name].js',
    },
    minify: true,
  },
  // IIFE bundled builds (self-contained, for testing and static serving)
  {
    input: './js/loader/src/loader.ts',
    output: {
      file: './js/loader/dist/loader.iife.js',
      format: 'iife',
    },
    minify: true,
  },
  {
    input: './js/loader/src/wc-loader.ts',
    output: {
      file: './js/loader/dist/wc-loader.iife.js',
      format: 'iife',
    },
    minify: true,
  },
  // HMR client (dev-only, injected by sol dev server)
  {
    input: './js/loader/src/hmr-client.ts',
    output: {
      file: './js/loader/dist/hmr-client.js',
      format: 'iife',
    },
    minify: false, // Keep readable for debugging
  },
  // Boot runtime IIFE (self-contained, for static sites)
  {
    input: './js/loader/src/boot/index.ts',
    output: {
      file: './js/loader/dist/boot.iife.js',
      format: 'iife',
      name: 'LunaBoot',
    },
    minify: true,
  },
]);
