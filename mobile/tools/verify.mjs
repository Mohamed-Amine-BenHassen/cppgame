/*
 * verify.mjs - the mobile side of `.\play.cmd verify`.
 *
 * Runs every floor through the SAME grader modules the tablet game ships,
 * against the SAME baked levels.json, on the SAME wasm toolchain. Nothing is
 * transpiled in between, so a pass here is evidence about the real thing.
 *
 *   node mobile/tools/verify.mjs            every reference solution must PASS
 *   node mobile/tools/verify.mjs --start    every starter must FAIL
 *   node mobile/tools/verify.mjs 17 25      just those floors
 *
 * The wasm-clang binaries are not in the repo. Point TOT_WASM_CLANG at a
 * checkout of binji/wasm-clang, or drop one in mobile/public/wasm-clang.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createWasmClangBackend } from '../src/toolchain/wasm-clang.js';
import { runTrial } from '../src/grader/trial.js';

const ROOT     = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const BUNDLE   = path.join(ROOT, 'mobile', 'src', 'content', 'levels.json');
const WASM_DIR = process.env.TOT_WASM_CLANG
  ?? path.join(ROOT, 'mobile', 'public', 'wasm-clang');

const die = (msg) => { console.error(`\n  ${msg}\n`); process.exit(2); };

if (!fs.existsSync(BUNDLE)) die('no levels.json - run: node mobile/tools/bake-levels.mjs');
for (const f of ['shared.js', 'clang', 'lld', 'memfs', 'sysroot.tar']) {
  if (!fs.existsSync(path.join(WASM_DIR, f))) {
    die(`missing ${f} in ${WASM_DIR}\n  set TOT_WASM_CLANG to a binji/wasm-clang checkout.`);
  }
}

const bundle = JSON.parse(fs.readFileSync(BUNDLE, 'utf8'));
const API = new Function(
  fs.readFileSync(path.join(WASM_DIR, 'shared.js'), 'utf8') + '\n; return API;')();

const args     = process.argv.slice(2);
const useStart = args.includes('--start');
const only     = args.filter((a) => !a.startsWith('--'));
const which    = useStart ? 'start' : 'solution';

const levels = only.length
  ? bundle.levels.filter((l) => only.some((o) => l.number === Number(o)))
  : bundle.levels;

const backend = await createWasmClangBackend({
  API,
  loadBinary: async (name) => fs.readFileSync(path.join(WASM_DIR, name)),
});

console.log(`\n  ${backend.label}  -  bundle baked ${bundle.generated}`);
console.log(`  ${levels.length} floors, ${which} code`);
console.log(useStart
  ? '  every starter must FAIL - a starter that passes means the floor teaches nothing\n'
  : '  every reference solution must PASS\n');

let wrong = 0, trialsPassed = 0, trialsTotal = 0;
const started = Date.now();

for (const level of levels) {
  const t0 = Date.now();
  let result = null, thrown = null;
  try {
    result = await runTrial(level, level[which], backend, { ruleFlags: bundle.ruleRegexFlags });
  } catch (e) { thrown = e; }
  const ms = Date.now() - t0;

  // A starter run is inverted: failing is the correct outcome.
  const cleared = Boolean(result?.allPass);
  const correct = useStart ? !cleared : cleared;
  if (!correct) wrong++;
  if (result && result.built && result.ruleIssues.length === 0) {
    trialsPassed += result.passed;
    trialsTotal += result.total;
  }

  let detail;
  if (thrown) detail = `threw: ${String(thrown.message).slice(0, 60)}`;
  else if (!result.built) detail = `did not compile - ${result.firstError.slice(0, 50)}`;
  else if (result.ruleIssues.length) detail = `source rule: ${result.ruleIssues[0]}`;
  else detail = `${result.passed}/${result.total} trials`;

  const tag = correct ? '  ok  ' : ' WRONG';
  console.log(`${tag}  ${level.slug.padEnd(30)} ${String(ms).padStart(6)}ms  ${detail}`);
}

const secs = ((Date.now() - started) / 1000).toFixed(1);
console.log('');
if (wrong === 0) {
  const tally = useStart
    ? `all ${levels.length} starters fail as they should`
    : `${levels.length}/${levels.length} floors, ${trialsPassed}/${trialsTotal} trials`;
  console.log(`  [ OK ] ${tally}  (${secs}s)\n`);
} else {
  console.log(`  [FAIL] ${wrong} floor(s) behaved wrongly  (${secs}s)\n`);
}
process.exit(wrong === 0 ? 0 : 1);
