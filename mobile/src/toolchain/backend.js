/*
 * backend.js - the contract every compile backend honours.
 *
 * Mirrors Build-Project / Invoke-Program (engine/Toolchain.ps1:100,160), which
 * hand back @{ Ok; Exe; Output } and @{ StdOut; TimedOut }. Keeping one shape
 * means the grader never knows or cares which compiler it is talking to.
 */

/** @typedef {{name: string, contents: string}} SourceFile */
/** @typedef {{ok: boolean, diagnostics: string, artifact: unknown}} BuildResult */
/** @typedef {{stdout: string, timedOut: boolean}} RunResult */

/**
 * @typedef {object} Backend
 * @property {string} label                          what to show the player ("clang 8 (wasm)")
 * @property {(files: SourceFile[], opts?: object) => Promise<BuildResult>} build
 * @property {(artifact: unknown, stdin: string, opts?: object) => Promise<RunResult>} run
 * @property {() => void|Promise<void>} resetArtifacts  clear save files between trials;
 *           may be async, since a worker-backed toolchain answers over a message port
 */

/** Files a level may write at runtime; cleared between trials so no case
 *  inherits state from the one before. Ports Reset-RunArtifacts
 *  (engine/Toolchain.ps1:150). */
export const RUN_ARTIFACTS = ['dungeon.sav', 'save.txt'];

/** Throws early if a backend is missing part of the contract. */
export function assertBackend(b) {
  for (const m of ['build', 'run', 'resetArtifacts']) {
    if (typeof b?.[m] !== 'function') throw new Error(`backend is missing ${m}()`);
  }
  return b;
}
