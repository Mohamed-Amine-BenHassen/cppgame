/*
 * worker-host.js - drives the toolchain worker, and kills it when it hangs.
 *
 * Satisfies the same Backend contract as the in-process backend, so runTrial
 * cannot tell the difference. What it adds is the watchdog: terminate() is the
 * only way to stop a wasm module mid-loop, so that is what a timeout does.
 *
 * Terminating throws away the worker's whole world - the untarred sysroot, the
 * compiled clang and lld modules, the linked program. The host hides that: it
 * remembers the last build and quietly repeats it on the next job, so a player
 * whose floor-5 loop never ends sees one failed trial and can carry straight
 * on, rather than a broken page.
 */

/** Long enough for a 6-file link on a slow tablet; short enough to not look dead. */
const BUILD_TIMEOUT_MS = 60_000;
/** Matches the desktop game's own limit (engine/Toolchain.ps1:162). */
const RUN_TIMEOUT_MS = 10_000;

class JobTimeout extends Error {}

/**
 * @param {object} opts
 * @param {string} [opts.baseUrl]  where the wasm binaries are served from
 * @param {string} [opts.std]
 * @param {(phase: string) => void} [opts.onStatus]  progress for the loading screen
 * @returns {import('./backend.js').Backend & {dispose(): void}}
 */
export function createWorkerBackend({
  baseUrl = '/wasm-clang',
  std = 'c++2a',
  onStatus = () => {},
  runTimeoutMs = RUN_TIMEOUT_MS,
  buildTimeoutMs = BUILD_TIMEOUT_MS,
} = {}) {
  let worker = null;
  let ready = null;
  let nextId = 1;
  const pending = new Map();

  /** The last successful build, so a respawned worker can catch up silently. */
  let lastBuild = null;

  function send(type, payload, timeoutMs) {
    return new Promise((resolve, reject) => {
      const id = nextId++;
      const timer = setTimeout(() => {
        pending.delete(id);
        reject(new JobTimeout(`${type} exceeded ${timeoutMs}ms`));
      }, timeoutMs);
      pending.set(id, { resolve, reject, timer });
      worker.postMessage({ id, type, payload });
    });
  }

  function spawn() {
    worker = new Worker(new URL('./toolchain-worker.js', import.meta.url), { type: 'module' });
    worker.onmessage = ({ data }) => {
      const job = pending.get(data.id);
      if (!job) return;                        // a job we already gave up on
      pending.delete(data.id);
      clearTimeout(job.timer);
      if (data.ok) job.resolve(data.value);
      else job.reject(new Error(data.message));
    };
    worker.onerror = (e) => {
      // The worker itself died; fail everything waiting rather than hang.
      for (const [, job] of pending) {
        clearTimeout(job.timer);
        job.reject(new Error(e.message || 'the toolchain worker stopped'));
      }
      pending.clear();
    };

    onStatus('starting the compiler');
    ready = send('init', { baseUrl, std }, buildTimeoutMs)
      .then((info) => { onStatus('ready'); return info; });
    return ready;
  }

  /** Nothing survives this; the next job pays to set the world up again. */
  function recycle() {
    if (worker) worker.terminate();
    for (const [, job] of pending) clearTimeout(job.timer);
    pending.clear();
    worker = null;
    ready = null;
    if (lastBuild) lastBuild.artifact = null;
  }

  async function ensureReady() {
    if (!worker) spawn();
    await ready;
  }

  /** After a recycle the program is gone; rebuild it before running again. */
  async function ensureBuilt() {
    await ensureReady();
    if (!lastBuild) return null;
    if (lastBuild.artifact) return lastBuild.artifact;
    onStatus('restoring the compiler');
    const result = await send('build',
      { files: lastBuild.files, tag: lastBuild.tag }, buildTimeoutMs);
    lastBuild.artifact = result.artifact;
    return result.artifact;
  }

  return {
    label: 'clang 8 (wasm, worker)',

    async build(files, { tag = 'floor' } = {}) {
      await ensureReady();
      lastBuild = { files, tag, artifact: null };
      try {
        const result = await send('build', { files, tag }, buildTimeoutMs);
        lastBuild.artifact = result.artifact;
        return result;
      } catch (error) {
        if (error instanceof JobTimeout) {
          recycle();
          return {
            ok: false,
            diagnostics: `error: the compiler gave up after ${Math.round(buildTimeoutMs / 1000)}s`,
            artifact: null,
          };
        }
        return { ok: false, diagnostics: `error: ${error.message}`, artifact: null };
      }
    },

    async run(artifact, stdin = '') {
      const live = (await ensureBuilt()) ?? artifact;
      try {
        return await send('run', { artifact: live, stdin }, runTimeoutMs);
      } catch (error) {
        if (error instanceof JobTimeout) {
          // The player wrote an endless loop. Kill it, report the trial as
          // timed out, and let the next strike rebuild from scratch.
          recycle();
          return { stdout: '', timedOut: true };
        }
        return { stdout: '', timedOut: false, error: error.message };
      }
    },

    async resetArtifacts() {
      if (!worker) return;                     // nothing to clear yet
      try { await send('reset', {}, runTimeoutMs); } catch { /* a dead worker has no files */ }
    },

    dispose() { recycle(); },
  };
}
