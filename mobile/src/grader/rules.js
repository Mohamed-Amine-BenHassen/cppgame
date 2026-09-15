/*
 * rules.js - require.txt / forbid.txt enforcement, ported from
 *            Test-SourceRules (engine/Quest.ps1:245).
 *
 * These are what stop a floor being beaten with the right output for the
 * wrong reasons - floor 12 wants a real std::vector<Monster>, floor 20
 * forbids delete, floor 25 insists the save goes through std::ofstream.
 *
 * CAREFUL: PowerShell's -match is case-INSENSITIVE. JavaScript's RegExp is
 * case-sensitive by default, so every pattern is compiled with 'i' or floors
 * silently mis-grade. The flag travels in the bundle as ruleRegexFlags.
 */

const SOURCE_EXT = /\.(cpp|h|hpp)$/i;

/**
 * All source text a rule is matched against: every .cpp/.h/.hpp joined by
 * newlines, exactly as the PowerShell version assembles it.
 * @param {{name:string, contents:string}[]} files
 */
export function sourceText(files) {
  return files.filter((f) => SOURCE_EXT.test(f.name)).map((f) => f.contents).join('\n');
}

/**
 * @param {{require:{pattern:string,why:string}[], forbid:{pattern:string,why:string}[]}} rules
 * @param {{name:string, contents:string}[]} files
 * @param {string} [flags] regex flags; pass the bundle's ruleRegexFlags
 * @returns {string[]} human-readable reasons, empty when the shape is right
 */
export function checkSourceRules(rules, files, flags = 'i') {
  const src = sourceText(files);
  const issues = [];
  const hits = (pattern) => {
    try { return new RegExp(pattern, flags).test(src); }
    catch { return false; }   // a broken pattern must never fail the player
  };
  for (const r of rules?.require ?? []) if (!hits(r.pattern)) issues.push(r.why);
  for (const r of rules?.forbid ?? []) if (hits(r.pattern)) issues.push(r.why);
  return issues;
}
