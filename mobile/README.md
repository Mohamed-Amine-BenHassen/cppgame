# Tower of Turing — tablet edition

The same game as `..\play.cmd`, in a browser, with the C++ compiler running
inside the page. No server, no install, works on a plane.

## Setup

```
npm install
npm run setup      # fetches the 18.6 MB toolchain into public/wasm-clang/
npm run dev        # then open the printed Network: URL on the tablet
```

## Scripts

| | |
|---|---|
| `npm run setup` | download clang, lld, memfs and the sysroot |
| `npm run bake` | rebuild `src/content/levels.json` from `..\levels\` |
| `npm run dev` | dev server, reachable over the LAN |
| `npm run build` | production build into `dist/` (59 MB, fully offline) |
| `npm test` | grading semantics, no toolchain needed |
| `npm run verify` | every reference solution must pass — the mirror of `play.cmd verify` |
| `npm run verify:starters` | every starter must fail |
| `npm run icons` | redraw the home-screen icons |

## How it fits together

`..\levels\` is the single source of truth for both versions of the game.
`bake-levels.mjs` turns it into one JSON; nothing is hand-copied, so the
desktop and tablet games cannot drift.

```
src/toolchain/   clang 8 + wasm-ld in a worker, with a watchdog
src/grader/      ports of ConvertTo-Comparable, Test-SourceRules, Get-TrialResult
src/editor/      CodeMirror 6, file tabs, symbol row
src/ui/          the tower, the lesson, the overlays
src/state/       progress, same shape as .state\progress.json
```

## Things that are load-bearing

- **Trials compare character for character, case-sensitively.** Every rule is
  pinned by `npm test`; the 61 expected outputs in `..\levels\` depend on them.
- **PowerShell's `-match` is case-insensitive, JavaScript's `RegExp` is not.**
  `require.txt` / `forbid.txt` patterns are compiled with `i`, carried in the
  bundle as `ruleRegexFlags`.
- **Ligatures are off.** A coding font draws `<=` as one glyph; this game is
  teaching someone what to actually type.
- **The player's code compiles at `-O0`,** like the desktop build, and in a
  worker so an endless loop can be terminated instead of wedging the page.
