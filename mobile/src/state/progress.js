/*
 * progress.js - who you are, how far you climbed.
 *
 * Deliberately the same shape as the desktop game's .state/progress.json
 * (engine/Quest.ps1:57), so a save can be carried between the two by hand.
 * Two fields are added: `hints`, which the desktop keeps in separate
 * .state/hints-<slug>.txt files, and `work`, the player's unsaved code.
 *
 * localStorage rather than IndexedDB: this is a few kilobytes of text, it has
 * to be readable synchronously while drawing the tower, and a save the player
 * can copy out of devtools is a feature rather than a problem.
 */

const KEY = 'tot.progress.v1';

/** Ranks, copied from engine/Ui.ps1:5. Clearing all 25 floors lands on 3100. */
export const RANKS = [
  { xp: 0, name: 'Null Pointer' },
  { xp: 120, name: 'Bit Squire' },
  { xp: 300, name: 'Byte Knight' },
  { xp: 560, name: 'Loop Warden' },
  { xp: 900, name: 'Function Adept' },
  { xp: 1300, name: 'Struct Artificer' },
  { xp: 1800, name: 'Class Sorcerer' },
  { xp: 2400, name: 'Pointer Magus' },
  { xp: 3100, name: 'Engine Architect' },
];

export function rankFor(xp) {
  let rank = RANKS[0].name;
  for (const r of RANKS) if (xp >= r.xp) rank = r.name;
  return rank;
}

/** The next rank and what it costs, or null at the top. */
export function nextRank(xp) {
  return RANKS.find((r) => xp < r.xp) ?? null;
}

const blank = () => ({
  hero: null,
  xp: 0,
  completed: [],
  attempts: {},
  hints: {},
  work: {},
  started: new Date().toISOString(),
});

export function loadProgress() {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return blank();
    const p = JSON.parse(raw);
    // Anything missing is filled in, so an older save still opens.
    return { ...blank(), ...p, completed: Array.isArray(p.completed) ? p.completed : [] };
  } catch {
    // A corrupt or unavailable store must never stop someone playing.
    return blank();
  }
}

export function saveProgress(p) {
  try { localStorage.setItem(KEY, JSON.stringify(p)); } catch { /* private mode, full disk */ }
  return p;
}

export const isDone = (p, level) => p.completed.includes(level.slug);

/**
 * A floor opens once every floor before it is cleared.
 * Ports Test-Unlocked (engine/Adventure.ps1:270).
 */
export function isUnlocked(p, levels, index) {
  if (isDone(p, levels[index])) return true;
  for (let i = 0; i < index; i++) if (!isDone(p, levels[i])) return false;
  return true;
}

/**
 * Award a floor. Returns what changed, so the victory screen can show the
 * XP counting up and call out a new rank.
 */
export function completeLevel(p, level) {
  const first = !isDone(p, level);
  const oldXp = p.xp;
  const oldRank = rankFor(oldXp);
  if (first) {
    p.completed = [...p.completed, level.slug];
    p.xp = oldXp + level.xp;
    saveProgress(p);
  }
  return {
    first,
    oldXp,
    newXp: p.xp,
    oldRank,
    newRank: rankFor(p.xp),
    rankChanged: rankFor(p.xp) !== oldRank,
  };
}

export function registerAttempt(p, level) {
  p.attempts[level.slug] = (p.attempts[level.slug] ?? 0) + 1;
  return saveProgress(p);
}

/* ---------- hints, handed out one at a time ---------- */

export const hintsSeen = (p, level) => p.hints[level.slug] ?? 0;

export function seeHint(p, level) {
  p.hints[level.slug] = hintsSeen(p, level) + 1;
  saveProgress(p);
  return p.hints[level.slug];
}

/* ---------- the player's code ---------- */

/** Keeps work across reloads; the desktop has workspace\<floor>\ for this. */
export function saveWork(p, level, files) {
  p.work[level.slug] = files;
  return saveProgress(p);
}

export const loadWork = (p, level) => p.work?.[level.slug] ?? null;

export function forgetWork(p, level) {
  delete p.work[level.slug];
  return saveProgress(p);
}

export function resetProgress() {
  try { localStorage.removeItem(KEY); } catch { /* nothing to do */ }
  return blank();
}
