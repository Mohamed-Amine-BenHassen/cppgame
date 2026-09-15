/*
 * toolchain-worker.js - the compiler, off the main thread.
 *
 * Everything here exists for one reason: a running WebAssembly module cannot
 * be interrupted from the outside. A player's `while (true)` on floor 5 would
 * wedge the page forever. Put it in a worker and the host can terminate it,
 * which is the only real answer - and the reason the desktop game's 10 second
 * timeout (engine/Toolchain.ps1:162) has a counterpart here at all.
 *
 * Keeping it off the main thread also stops a 3 second link from freezing the
 * UI mid-animation.
 */
import { createWasmClangBackend } from './wasm-clang.js';

let backend = null;

/** shared.js is an upstream IIFE, not a module; evaluate it for its API. */
async function loadAPI(baseUrl) {
  const res = await fetch(`${baseUrl}/shared.js`);
  if (!res.ok) throw new Error(`cannot load shared.js (${res.status})`);
  return new Function(`${await res.text()}\n; return API;`)();
}

async function init({ baseUrl, std }) {
  const API = await loadAPI(baseUrl);
  backend = await createWasmClangBackend({
    API,
    std,
    loadBinary: async (name) => {
      const res = await fetch(`${baseUrl}/${name}`);
      if (!res.ok) throw new Error(`cannot load ${name} (${res.status})`);
      return res.arrayBuffer();
    },
  });
  return { label: backend.label };
}

self.onmessage = async (event) => {
  const { id, type, payload } = event.data ?? {};
  try {
    let value;
    switch (type) {
      case 'init':
        value = await init(payload);
        break;
      case 'build':
        value = await backend.build(payload.files, { tag: payload.tag });
        break;
      case 'run':
        value = await backend.run(payload.artifact, payload.stdin);
        break;
      case 'reset':
        backend.resetArtifacts();
        value = null;
        break;
      default:
        throw new Error(`unknown job: ${type}`);
    }
    self.postMessage({ id, ok: true, value });
  } catch (error) {
    // Never let a job die silently - the host is waiting on this id.
    self.postMessage({ id, ok: false, message: String(error?.message ?? error) });
  }
};
