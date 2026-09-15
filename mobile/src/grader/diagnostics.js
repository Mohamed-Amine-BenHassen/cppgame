/*
 * diagnostics.js - turning a wall of compiler output into the one line the
 *                  player needs. Ports Get-FirstError (engine/Adventure.ps1:528).
 *
 * "Read the FIRST error, not the last. One mistake often causes ten."
 */

/** clang is invoked with -fcolor-diagnostics; strip the escapes for display. */
export function stripAnsi(text) {
  return String(text ?? '').replace(/\x1b\[[0-9;]*m/g, '');
}

/**
 * First line mentioning an error (case-insensitive, as PowerShell -match is),
 * falling back to the first non-blank line.
 * @param {string} text raw compiler output
 */
export function firstError(text) {
  const lines = stripAnsi(text).split(/\r?\n/);
  for (const l of lines) if (/error/i.test(l)) return l.trim();
  return (lines.find((l) => l.trim()) ?? '').trim();
}

/** Every error line, for the "show me everything" view. */
export function allErrors(text) {
  return stripAnsi(text).split(/\r?\n/).map((l) => l.trim()).filter((l) => /error/i.test(l));
}
