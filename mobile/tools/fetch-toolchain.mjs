/*
 * fetch-toolchain.mjs - downloads the in-browser C++ compiler.
 *
 *   node mobile/tools/fetch-toolchain.mjs
 *
 * These five files are the whole toolchain: clang 8 and wasm-ld compiled to
 * WebAssembly, an in-memory filesystem, and a sysroot holding libc++ and the
 * standard headers. Roughly 18 MB over the wire, 58 MB on disk.
 *
 * They are deliberately NOT committed - too large, and not ours. Everything
 * here is from binji/wasm-clang (Apache-2.0). Run this once after cloning;
 * the files land where verify.mjs and the dev server both expect them.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT   = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const OUT    = process.env.TOT_WASM_CLANG ?? path.join(ROOT, 'mobile', 'public', 'wasm-clang');
const ORIGIN = 'https://binji.github.io/wasm-clang';

/* Expected sizes are a sanity check, not a security control: a truncated
 * download otherwise shows up much later as a baffling wasm error. */
const FILES = [
  { name: 'shared.js',   bytes: 23973 },
  { name: 'memfs',       bytes: 345442 },
  { name: 'sysroot.tar', bytes: 9297920 },
  { name: 'lld',         bytes: 19490094 },
  { name: 'clang',       bytes: 31214472 },
];

const mb = (n) => `${(n / 1048576).toFixed(1)} MB`;

const total = FILES.reduce((n, f) => n + f.bytes, 0);
console.log(`\n  fetching the in-browser C++ toolchain  (${mb(total)} on disk)`);
console.log(`  from ${ORIGIN}`);
console.log(`  into ${path.relative(ROOT, OUT) || OUT}\n`);

fs.mkdirSync(OUT, { recursive: true });

let fetched = 0, skipped = 0;
for (const file of FILES) {
  const dest = path.join(OUT, file.name);

  if (fs.existsSync(dest) && fs.statSync(dest).size === file.bytes) {
    console.log(`  have  ${file.name.padEnd(12)} ${mb(file.bytes).padStart(9)}`);
    skipped++;
    continue;
  }

  process.stdout.write(`  get   ${file.name.padEnd(12)} ${mb(file.bytes).padStart(9)} ... `);
  const res = await fetch(`${ORIGIN}/${file.name}`);
  if (!res.ok) {
    console.log('FAILED');
    console.error(`\n  ${ORIGIN}/${file.name} returned ${res.status} ${res.statusText}\n`);
    process.exit(1);
  }
  const body = Buffer.from(await res.arrayBuffer());

  // Write beside the target first so an interrupted run never leaves a
  // half-file that looks valid to the next one.
  const tmp = `${dest}.partial`;
  fs.writeFileSync(tmp, body);
  fs.renameSync(tmp, dest);
  fetched++;

  console.log(body.length === file.bytes ? 'ok' : `ok (${mb(body.length)}, expected ${mb(file.bytes)})`);
}

console.log(`\n  ${fetched} fetched, ${skipped} already present.`);
console.log('  check it with:  node mobile/tools/verify.mjs\n');
