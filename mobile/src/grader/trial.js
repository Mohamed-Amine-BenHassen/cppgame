/*
 * trial.js - facing a guardian. Ports Get-TrialResult (engine/Adventure.ps1:427)
 *            and Get-Guardian (engine/Adventure.ps1:520).
 *
 * The fight model, unchanged from the desktop game:
 *
 *   the guardian's hit points  = the number of trials on the floor
 *   damage dealt               = the number of trials that pass
 *
 *   does not compile    -> SHIELDED, no damage, show the FIRST compiler error
 *   breaks a floor rule -> the shape is wrong, no damage
 *   some trials pass    -> that much damage, show the first differing line
 *   all trials pass     -> the guardian breaks apart
 */
import { toComparable, linesEqual, firstDiff } from './compare.js';
import { checkSourceRules } from './rules.js';
import { firstError } from './diagnostics.js';

/** @typedef {import('../toolchain/backend.js').Backend} Backend */

export const SENTINEL = [
  '     .-----.  ',
  '    / o   o \\ ',
  '   |    -    |',
  '    \\  ===  / ',
  '     "-----"  ',
];

export const WARDEN = [
  '   \\  /^\\  /  ',
  '   <\\_| |_/>  ',
  '    | o o |   ',
  '   _|  V  |_  ',
  '  /_|_____|_\\ ',
];

/** Boss floors get the Warden; everything else gets the Sentinel. */
export function guardianFor(level) {
  return level.boss
    ? { art: WARDEN, name: 'THE WARDEN', color: 'magenta' }
    : { art: SENTINEL, name: 'THE SENTINEL', color: 'blue' };
}

/**
 * Build the player's code, enforce the floor's rules, run every trial.
 *
 * @param {object} level     one entry from levels.json
 * @param {{name:string,contents:string}[]} files   the player's source
 * @param {Backend} backend
 * @param {{ruleFlags?: string}} [opts]
 */
export async function runTrial(level, files, backend, { ruleFlags = 'i' } = {}) {
  const result = {
    built: false,
    buildOutput: '',
    firstError: '',
    ruleIssues: [],
    cases: [],
    passed: 0,
    total: level.tests?.length ?? 0,
    allPass: false,
  };

  const build = await backend.build(files, { tag: level.slug.replace(/\W/g, '_') });
  result.buildOutput = build.diagnostics;
  if (!build.ok) {
    result.firstError = firstError(build.diagnostics);
    return result;                      // SHIELDED - no damage is dealt
  }
  result.built = true;

  // Right output for the wrong reasons still fails the floor.
  result.ruleIssues = checkSourceRules(level.rules, files, ruleFlags);
  if (result.ruleIssues.length > 0) return result;

  for (const test of level.tests ?? []) {
    // No trial may inherit a save file from the trial before it. Awaited
    // because a worker-backed toolchain answers across a message boundary;
    // the in-process one returns undefined and this costs nothing.
    await backend.resetArtifacts();

    const run = await backend.run(build.artifact, test.stdin ?? '');
    const expected = toComparable(test.expected);
    const actual = toComparable(run.stdout);
    const pass = !run.timedOut && linesEqual(expected, actual);
    if (pass) result.passed++;

    result.cases.push({
      name: test.name,
      label: test.title,
      pass,
      timedOut: run.timedOut,
      expected,
      actual,
      diff: pass ? null : firstDiff(expected, actual),
    });
  }

  result.allPass = result.built
    && result.ruleIssues.length === 0
    && result.total > 0
    && result.passed === result.total;

  return result;
}

/**
 * Turn two consecutive strikes into the lines the arena log shows.
 * Ports the messaging in Invoke-Trial (engine/Adventure.ps1:665-700).
 *
 * @param {object} result      from runTrial
 * @param {number} prevPassed  passing count on the previous strike, -1 on the first
 */
export function strikeLog(result, prevPassed = -1) {
  const log = [];

  if (!result.built) {
    log.push({ text: `it rejects you: ${result.firstError}`, tone: 'red' });
    return log;
  }
  if (result.ruleIssues.length > 0) {
    log.push({ text: 'it compiles, but the shape is wrong.', tone: 'orange' });
    for (const issue of result.ruleIssues) log.push({ text: issue, tone: 'orange' });
    return log;
  }

  if (prevPassed >= 0 && result.passed > prevPassed) {
    const hit = result.passed - prevPassed;
    log.push({ text: `a hit! ${hit} more trial(s) pass.`, tone: 'lime' });
  } else if (prevPassed > result.passed) {
    log.push({ text: 'it recovers - something that passed now fails.', tone: 'orange' });
  }

  if (result.allPass) {
    log.push({ text: 'every trial passes. the guardian breaks apart.', tone: 'lime' });
    return log;
  }

  const failing = result.cases.find((c) => !c.pass);
  if (failing) {
    if (failing.timedOut) {
      log.push({ text: 'your program never stopped. an endless loop?', tone: 'red' });
    } else if (failing.diff) {
      log.push({ text: `line ${failing.diff.line} yours: ${failing.diff.yours}`, tone: 'red' });
      log.push({ text: `line ${failing.diff.line} wants: ${failing.diff.wants}`, tone: 'green' });
    }
  }
  return log;
}
