/*
 * wasm-clang.js - clang 8 + wasm-ld running in WebAssembly.
 *
 * Wraps the upstream wasm-clang API (binji/wasm-clang, Apache-2.0). The host
 * supplies `API` and a binary loader, so the same module drives Node (fs) and
 * the browser (fetch) unchanged.
 *
 * Two things upstream does not do, which the game needs:
 *   - link more than one object file  (floors 19 and 21-25 are multi-file)
 *   - keep compiler diagnostics apart from the program's own stdout
 *     (both arrive through the single hostWrite callback)
 */
import { RUN_ARTIFACTS } from './backend.js';

const LIBDIR = 'lib/wasm32-wasi';

/**
 * @param {object} opts
 * @param {Function} opts.API            the upstream API constructor
 * @param {(name: string) => Promise<ArrayBuffer|Uint8Array>} opts.loadBinary
 * @param {string} [opts.std]            language standard; desktop builds with C++20
 * @param {string} [opts.opt]            optimisation level. 0 by default: nobody
 *        here is benchmarking their hero, the desktop game does not optimise
 *        either, and -O2 costs seconds per strike on a tablet for no gain.
 * @returns {Promise<import('./backend.js').Backend>}
 */
export async function createWasmClangBackend({ API, loadBinary, std = 'c++2a', opt = '0' }) {
  let sink = [];
  const api = new API({
    readBuffer: (name) => loadBinary(name),
    compileStreaming: async (name) => WebAssembly.compile(await loadBinary(name)),
    hostWrite: (s) => sink.push(s),
  });

  /* hostWrite is the only output channel, shared by clang's diagnostics and by
   * the compiled program. Swapping the sink around a phase is what separates
   * "the compiler complained" from "your game printed".
   *
   * A tool that exits non-zero throws out of api.run(), and a player's program
   * can trap outright. Either way the text written before the failure is the
   * useful part, so capture returns it alongside the error instead of losing
   * it up the stack. */
  const capture = async (fn) => {
    const outer = sink;
    sink = [];
    try {
      await fn();
      return { text: sink.join(''), error: null };
    } catch (error) {
      return { text: sink.join(''), error };
    } finally {
      sink = outer;
    }
  };

  await api.ready;

  const memfs = api.memfs;
  const stagePath = (p) => { memfs.mem.check(); memfs.mem.write(memfs.exports.GetPathBuf(), p); };

  return {
    label: 'clang 8 (wasm)',

    async build(files, { tag = 'floor' } = {}) {
      const objs = [];
      // api.run() banners each argv through hostLog. That banner contains
      // "-ferror-limit", so leaving it in the diagnostics makes "the first
      // line mentioning an error" match the command line instead of the
      // actual complaint. Mute it and keep only what the tools said.
      const log = api.hostLog;
      api.hostLog = () => {};
      const { text: diagnostics, error } = await capture(async () => {
        // Headers must exist in the filesystem so #include resolves, but only
        // .cpp files are translation units - compiling a header would define
        // its symbols twice and the link would fail.
        for (const f of files) memfs.addFile(f.name, f.contents);

        const clang = await api.getModule(api.clangFilename);
        const units = files.filter((f) => f.name.endsWith('.cpp'));
        for (const [i, f] of units.entries()) {
          const obj = `${tag}_${i}.o`;
          await api.run(clang, 'clang', '-cc1', '-emit-obj', ...api.clangCommonArgs,
            `-O${opt}`, `-std=${std}`, '-o', obj, '-x', 'c++', f.name);
          objs.push(obj);
        }

        const lld = await api.getModule(api.lldFilename);
        await api.run(lld, 'wasm-ld', '--no-threads', '--export-dynamic',
          '-z', 'stack-size=1048576', `-L${LIBDIR}`, `${LIBDIR}/crt1.o`,
          ...objs, '-lc', '-lc++', '-lc++abi', '-lcanvas', '-o', `${tag}.wasm`);
      });
      api.hostLog = log;

      // clang reports failure through its diagnostics; wasm-ld reports it by
      // exiting non-zero, which arrives here as `error`. Undefined symbols -
      // a declared-but-never-defined function - come through that second path,
      // so treating a throw as anything but a build failure would crash the
      // arena on one of the commonest beginner mistakes.
      const ok = !error && !/\berror\b/i.test(diagnostics);
      const detail = ok || !error || /\berror\b/i.test(diagnostics)
        ? diagnostics
        : `${diagnostics}\nerror: the linker refused it (${error.message})`;
      return { ok, diagnostics: detail, artifact: ok ? { wasm: `${tag}.wasm` } : null };
    },

    async run(artifact, stdin = '') {
      memfs.setStdinStr(stdin);
      const mod = await WebAssembly.compile(memfs.getFileContents(artifact.wasm));
      // api.run() banners its argv through hostLog into the same sink as the
      // program's stdout; mute it so we capture only what the program printed.
      const log = api.hostLog;
      api.hostLog = () => {};
      try {
        // A program that exits non-zero or traps (a stray pointer on floor 20,
        // say) still printed something first. That output is what the trial is
        // graded on - a crash is a failed trial, never a crashed game.
        const { text: stdout } = await capture(async () => { await api.run(mod, artifact.wasm); });
        return { stdout, timedOut: false };
      } finally {
        api.hostLog = log;
      }
    },

    /* A real removal, not a truncate: std::ifstream can tell a missing file
     * from an empty one, and floors 17/24/25 lean on exactly that. */
    resetArtifacts() {
      memfs.hostMem = memfs.mem;
      for (const name of RUN_ARTIFACTS) {
        stagePath(name);
        memfs.exports.path_unlink_file(3, memfs.exports.GetPathBuf(), name.length);
      }
    },
  };
}
