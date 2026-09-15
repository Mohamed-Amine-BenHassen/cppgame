/*
 * compare.js - output comparison, ported from engine/Quest.ps1:230
 *              (ConvertTo-Comparable) and engine/Adventure.ps1:537
 *              (Get-FirstDiff).
 *
 * The 61 expected outputs in levels/ were generated against these exact
 * semantics, so every rule below is load-bearing:
 *
 *   - CRLF collapses to LF
 *   - each line is right-trimmed  (trailing spaces never count)
 *   - trailing blank lines are dropped  (but interior blanks are kept)
 *   - comparison is CASE-SENSITIVE     (PowerShell -cne, not -ne)
 */

/**
 * @param {string|null|undefined} text
 * @returns {string[]} lines, ready to compare
 */
export function toComparable(text) {
  if (text === null || text === undefined) return [];
  const lines = String(text).replace(/\r\n/g, '\n').split('\n').map((l) => l.replace(/\s+$/, ''));
  let end = lines.length - 1;
  while (end >= 0 && lines[end] === '') end--;
  return end < 0 ? [] : lines.slice(0, end + 1);
}

/**
 * Case-sensitive line-by-line equality.
 * @param {string[]} a @param {string[]} b
 */
export function linesEqual(a, b) {
  if (a.length !== b.length) return false;
  for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
  return true;
}

/**
 * The first line where actual departs from expected - this is what the arena
 * shows the player. Missing lines on either side read as '(nothing)'.
 *
 * @param {string[]} expected @param {string[]} actual
 * @returns {{line:number, yours:string, wants:string}|null}
 */
export function firstDiff(expected, actual) {
  const max = Math.max(expected.length, actual.length);
  for (let i = 0; i < max; i++) {
    const a = i < actual.length ? actual[i] : null;
    const e = i < expected.length ? expected[i] : null;
    if (a !== e) {
      return {
        line: i + 1,
        yours: a === null ? '(nothing)' : a,
        wants: e === null ? '(nothing)' : e,
      };
    }
  }
  return null;
}
