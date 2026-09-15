/*
 * test-grader.mjs - locks in the exact grading semantics.
 *
 *   node --test mobile/tools/test-grader.mjs
 *
 * These run in milliseconds and need no toolchain. Every rule asserted here is
 * one the 61 expected outputs in levels/ silently depend on - if one of these
 * ever changes, floors start passing or failing for the wrong reasons.
 */
import test from 'node:test';
import assert from 'node:assert/strict';

import { toComparable, linesEqual, firstDiff } from '../src/grader/compare.js';
import { checkSourceRules, sourceText } from '../src/grader/rules.js';
import { firstError, stripAnsi, allErrors } from '../src/grader/diagnostics.js';

/* ---------- toComparable: ports ConvertTo-Comparable (Quest.ps1:230) ------- */

test('CRLF collapses to LF', () => {
  assert.deepEqual(toComparable('a\r\nb'), ['a', 'b']);
});

test('trailing whitespace on a line never counts', () => {
  assert.deepEqual(toComparable('gold: 42   \nhp: 100\t'), ['gold: 42', 'hp: 100']);
});

test('trailing blank lines are dropped', () => {
  assert.deepEqual(toComparable('a\nb\n\n\n'), ['a', 'b']);
});

test('interior blank lines are KEPT - floors print them on purpose', () => {
  assert.deepEqual(toComparable('a\n\nb'), ['a', '', 'b']);
});

test('empty, blank-only, null and undefined all compare as no output', () => {
  for (const input of ['', '   \n\n', null, undefined]) {
    assert.deepEqual(toComparable(input), [], `failed for ${JSON.stringify(input)}`);
  }
});

test('a file with no trailing newline still yields its last line', () => {
  // levels/01 expects exactly this shape - the .out file ends mid-line.
  assert.deepEqual(toComparable('one\ntwo'), ['one', 'two']);
});

/* ---------- linesEqual: PowerShell -cne, so case is significant ----------- */

test('comparison is case-SENSITIVE', () => {
  assert.equal(linesEqual(['Kaelen'], ['kaelen']), false);
  assert.equal(linesEqual(['Kaelen'], ['Kaelen']), true);
});

test('a missing or extra line fails the trial', () => {
  assert.equal(linesEqual(['a', 'b'], ['a']), false);
  assert.equal(linesEqual(['a'], ['a', 'b']), false);
});

/* ---------- firstDiff: what the arena shows the player -------------------- */

test('reports the first differing line, counting from 1', () => {
  const d = firstDiff(['a', 'b', 'c'], ['a', 'X', 'c']);
  assert.deepEqual(d, { line: 2, yours: 'X', wants: 'b' });
});

test('output that stops short reads as (nothing)', () => {
  assert.deepEqual(firstDiff(['a', 'b'], ['a']), { line: 2, yours: '(nothing)', wants: 'b' });
});

test('output that runs long reads as (nothing) on the wanted side', () => {
  assert.deepEqual(firstDiff(['a'], ['a', 'b']), { line: 2, yours: 'b', wants: '(nothing)' });
});

test('identical output has no diff', () => {
  assert.equal(firstDiff(['a', 'b'], ['a', 'b']), null);
});

/* ---------- source rules: require.txt / forbid.txt ------------------------ */

const cpp = (contents) => [{ name: 'main.cpp', contents }];

test('a satisfied require raises nothing', () => {
  const rules = { require: [{ pattern: 'std::cout', why: 'print with std::cout' }], forbid: [] };
  assert.deepEqual(checkSourceRules(rules, cpp('std::cout << "hi";')), []);
});

test('an unmet require raises its reason', () => {
  const rules = { require: [{ pattern: 'std::cout', why: 'print with std::cout' }], forbid: [] };
  assert.deepEqual(checkSourceRules(rules, cpp('printf("hi");')), ['print with std::cout']);
});

test('a tripped forbid raises its reason', () => {
  const rules = { require: [], forbid: [{ pattern: '\\b42\\b', why: 'the gold must be calculated' }] };
  assert.deepEqual(checkSourceRules(rules, cpp('int gold = 42;')), ['the gold must be calculated']);
});

test('PowerShell -match is case-insensitive and so is this', () => {
  // The whole reason ruleRegexFlags travels in the bundle. Get this wrong and
  // floors mis-grade silently rather than loudly.
  const rules = { require: [{ pattern: 'STD::COUT', why: 'nope' }], forbid: [] };
  assert.deepEqual(checkSourceRules(rules, cpp('std::cout << 1;')), []);
});

test('headers count as source, other files do not', () => {
  const files = [
    { name: 'main.cpp', contents: 'int main(){}' },
    { name: 'hero.h', contents: 'struct Hero {};' },
    { name: 'notes.txt', contents: 'struct Villain {};' },
  ];
  const text = sourceText(files);
  assert.ok(text.includes('struct Hero'));
  assert.ok(!text.includes('struct Villain'));
});

test('a rule with a broken regex never fails the player', () => {
  const rules = { require: [], forbid: [{ pattern: '([unclosed', why: 'should not fire' }] };
  assert.deepEqual(checkSourceRules(rules, cpp('anything')), []);
});

/* ---------- diagnostics: Get-FirstError (Adventure.ps1:528) --------------- */

test('the FIRST error is the one shown, not the last', () => {
  const out = 'main.cpp:3:5: error: expected \';\'\nmain.cpp:9:1: error: and ten more';
  assert.equal(firstError(out), "main.cpp:3:5: error: expected ';'");
});

test('error matching ignores case', () => {
  assert.equal(firstError('LINK : fatal ERROR LNK1104'), 'LINK : fatal ERROR LNK1104');
});

test('with no error line, the first non-blank line stands in', () => {
  assert.equal(firstError('\n\n  something went wrong  \n'), 'something went wrong');
});

test('colour escapes are stripped before display', () => {
  assert.equal(stripAnsi('\x1b[1;31merror:\x1b[0m bad'), 'error: bad');
  assert.equal(firstError('\x1b[1;31mmain.cpp:1:1: error: bad\x1b[0m'), 'main.cpp:1:1: error: bad');
});

test('allErrors collects every error line', () => {
  const out = 'note: here\nmain.cpp:1: error: one\nmain.cpp:2: error: two';
  assert.deepEqual(allErrors(out), ['main.cpp:1: error: one', 'main.cpp:2: error: two']);
});
