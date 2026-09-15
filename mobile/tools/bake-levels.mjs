/*
 * bake-levels.mjs - turns levels/** into one JSON the tablet build can ship.
 *
 * levels/ stays the single source of truth for BOTH versions of the game.
 * Nothing here is hand-maintained; re-run this whenever a floor changes.
 *
 *   node mobile/tools/bake-levels.mjs           bake
 *   node mobile/tools/bake-levels.mjs --check   validate only, non-zero on problems
 *
 * The shape mirrors Get-Levels (engine/Quest.ps1:14-40) on purpose - if the
 * desktop engine grows a field, it belongs here under the same name.
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT   = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', '..');
const LEVELS = path.join(ROOT, 'levels');
const OUT    = path.join(ROOT, 'mobile', 'src', 'content', 'levels.json');

const SOURCE_EXT = new Set(['.cpp', '.h', '.hpp']);
const problems = [];
const note = (slug, msg) => problems.push(`${slug}: ${msg}`);

const readText = (p) => fs.readFileSync(p, 'utf8');
const listDir  = (p) => (fs.existsSync(p) ? fs.readdirSync(p).sort() : []);

/* Source files are carried verbatim; headers ship too, because they have to
 * exist in the in-browser filesystem for #include to resolve even though only
 * .cpp files become translation units. */
function readSources(dir, slug, which) {
  if (!fs.existsSync(dir)) { note(slug, `missing ${which}/`); return []; }
  const files = listDir(dir)
    .filter((f) => SOURCE_EXT.has(path.extname(f)))
    .map((name) => ({ name, contents: readText(path.join(dir, name)) }));
  if (!files.length) note(slug, `${which}/ has no source files`);
  if (!files.some((f) => f.name.endsWith('.cpp'))) note(slug, `${which}/ has no .cpp`);
  return files;
}

/* require.txt / forbid.txt: "<regex> || <why>", # comments, blank lines skipped.
 * Ports Test-SourceRules (engine/Quest.ps1:245-270). */
function readRules(levelDir, slug) {
  const out = { require: [], forbid: [] };
  for (const kind of ['require', 'forbid']) {
    const file = path.join(levelDir, `${kind}.txt`);
    if (!fs.existsSync(file)) continue;
    for (const line of readText(file).split(/\r?\n/)) {
      if (!line.trim() || line.trimStart().startsWith('#')) continue;
      const at      = line.indexOf('||');
      const pattern = (at === -1 ? line : line.slice(0, at)).trim();
      const why     = at === -1 ? `source rule: ${pattern}` : line.slice(at + 2).trim();
      if (!pattern) continue;
      try { new RegExp(pattern, 'i'); }
      catch (e) { note(slug, `${kind}.txt: bad regex ${JSON.stringify(pattern)} - ${e.message}`); }
      out[kind].push({ pattern, why });
    }
  }
  return out;
}

function readTests(levelDir, slug) {
  const dir = path.join(levelDir, 'tests');
  const tests = listDir(dir)
    .filter((f) => f.endsWith('.in'))
    .map((f) => {
      const name    = f.slice(0, -3);
      const outFile = path.join(dir, `${name}.out`);
      if (!fs.existsSync(outFile)) { note(slug, `trial ${name} has no .out`); return null; }
      const titleFile = path.join(dir, `${name}.title`);
      return {
        name,
        title: fs.existsSync(titleFile) ? readText(titleFile).trim() : `trial ${name}`,
        stdin: readText(path.join(dir, f)),
        expected: readText(outFile),
      };
    })
    .filter(Boolean);
  if (!tests.length) note(slug, 'no trials - the guardian would have 0 hit points');
  return tests;
}

function bakeLevel(slug) {
  const dir      = path.join(LEVELS, slug);
  const metaFile = path.join(dir, 'meta.json');
  if (!fs.existsSync(metaFile)) return null;

  let meta;
  try { meta = JSON.parse(readText(metaFile)); }
  catch (e) { note(slug, `meta.json is not valid JSON - ${e.message}`); return null; }

  const briefFile = path.join(dir, 'brief.md');
  if (!fs.existsSync(briefFile)) note(slug, 'missing brief.md');

  for (const field of ['title', 'act', 'xp']) {
    if (meta[field] === undefined) note(slug, `meta.json has no "${field}"`);
  }

  return {
    slug,
    number:   Number.parseInt(slug, 10),
    title:    meta.title,
    act:      meta.act,
    tagline:  meta.tagline ?? '',
    xp:       Number(meta.xp) || 0,
    boss:     Boolean(meta.boss),
    concepts: meta.concepts ?? [],
    hints:    meta.hints ?? [],
    brief:    fs.existsSync(briefFile) ? readText(briefFile) : '',
    start:    readSources(path.join(dir, 'start'), slug, 'start'),
    solution: readSources(path.join(dir, 'solution'), slug, 'solution'),
    rules:    readRules(dir, slug),
    tests:    readTests(dir, slug),
  };
}

const slugs  = listDir(LEVELS).filter((d) => /^\d\d-/.test(d)
  && fs.statSync(path.join(LEVELS, d)).isDirectory());
const levels = slugs.map(bakeLevel).filter(Boolean);

const seen = new Set();
for (const l of levels) {
  if (seen.has(l.number)) note(l.slug, `duplicate floor number ${l.number}`);
  seen.add(l.number);
}

const bundle = {
  generated: new Date().toISOString(),
  // PowerShell's -match is case-INSENSITIVE; JS RegExp is not. The runtime
  // must honour this or floors silently mis-grade.
  ruleRegexFlags: 'i',
  totalXp: levels.reduce((n, l) => n + l.xp, 0),
  levelCount: levels.length,
  trialCount: levels.reduce((n, l) => n + l.tests.length, 0),
  levels,
};

const check = process.argv.includes('--check');

if (problems.length) {
  console.error(`\n  ${problems.length} problem(s):\n`);
  for (const p of problems) console.error(`    ${p}`);
  console.error('');
  if (check) process.exit(1);
}

if (check) {
  console.log(`  ${bundle.levelCount} floors, ${bundle.trialCount} trials, ${bundle.totalXp} XP - all well-formed`);
  process.exit(0);
}

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, JSON.stringify(bundle, null, 2), 'utf8');

const kb = (n) => `${(n / 1024).toFixed(0)} KB`;
console.log(`  baked ${bundle.levelCount} floors, ${bundle.trialCount} trials, ${bundle.totalXp} XP`);
console.log(`  -> ${path.relative(ROOT, OUT)}  (${kb(fs.statSync(OUT).size)})`);
