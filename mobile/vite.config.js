import { defineConfig } from 'vite';

export default defineConfig({
  // The 58 MB toolchain is served straight out of vendor/ rather than copied
  // into the bundle, so /wasm-clang/clang resolves in dev and in a build.
  publicDir: 'public',
  server: {
    host: true,          // reachable from the tablet over the LAN
    port: 5173,
  },
  build: {
    target: 'es2022',    // top-level await in the worker
  },
  worker: {
    format: 'es',
  },
});
