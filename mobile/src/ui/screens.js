/*
 * screens.js - the tower map, and the overlays that sit on top of a fight.
 *
 * Ports Invoke-Tower (engine/Adventure.ps1:281), Show-Hints (:738),
 * Show-Answer (:825), Invoke-Victory (:871) and Invoke-Ending (:944).
 *
 * The desktop draws these as full-screen text frames. Here the tower is a
 * scrolling list and the rest are overlays, but the rules are identical:
 * floors open in order, hints come one at a time, and the answer is always
 * available to anyone who asks for it.
 */
import { isDone, isUnlocked, rankFor, nextRank, hintsSeen, seeHint } from '../state/progress.js';
import { guardianFor } from '../grader/trial.js';

const el = (tag, className, text) => {
  const n = document.createElement(tag);
  if (className) n.className = className;
  if (text !== undefined) n.textContent = text;
  return n;
};

/* ---------------------------- the tower ---------------------------- */

/**
 * @param {object} opts
 * @param {HTMLElement} opts.mount
 * @param {object} opts.bundle
 * @param {object} opts.progress
 * @param {(level: object) => void} opts.onEnter
 */
export function renderTower({ mount, bundle, progress, onEnter }) {
  mount.replaceChildren();
  const levels = bundle.levels;

  // --- the climb so far
  const head = el('div', 'tower-head');
  const rank = rankFor(progress.xp);
  const next = nextRank(progress.xp);

  head.append(el('div', 'rank', rank));
  const xpLine = el('div', 'xpline');
  const bar = el('span', 'bar');
  const fill = el('i');
  fill.style.width = `${(progress.xp / bundle.totalXp) * 100}%`;
  bar.append(fill);
  xpLine.append(el('span', 'xp', `${progress.xp} / ${bundle.totalXp} XP`), bar);
  head.append(xpLine);
  head.append(el('div', 'sub',
    next ? `${next.xp - progress.xp} XP to ${next.name}`
         : 'every rank earned. the tower has nothing left to teach you.'));
  mount.append(head);

  // --- floors, grouped by act, exactly as the map does
  let act = null;
  levels.forEach((level, i) => {
    if (level.act !== act) {
      act = level.act;
      mount.append(el('h2', 'act', act));
    }

    const done = isDone(progress, level);
    const open = isUnlocked(progress, levels, i);
    const current = open && !done;

    const row = el('button', `floor${done ? ' done' : ''}${current ? ' current' : ''}${open ? '' : ' sealed'}`);
    row.type = 'button';

    row.append(el('span', 'mark', done ? '✓' : open ? '›' : '·'));
    row.append(el('span', 'num', String(level.number).padStart(2, '0')));

    const mid = el('span', 'mid');
    mid.append(el('span', 'title', level.title));
    mid.append(el('span', 'tag', open ? level.tagline : 'the door will not open'));
    row.append(mid);

    if (level.boss) row.append(el('span', 'boss', 'BOSS'));
    row.append(el('span', 'xpv', String(level.xp)));

    if (open) row.addEventListener('click', () => onEnter(level));
    else row.disabled = true;

    mount.append(row);
  });

  if (progress.completed.length === levels.length) {
    const done = el('div', 'tower-done');
    done.append(el('div', 'big', 'THE CLIMB IS DONE'));
    done.append(el('div', 'sub', 'Twenty-five floors. Every one of them compiled.'));
    mount.append(done);
  }
}

/* --------------------------- the overlays -------------------------- */

let closer = null;

export function closeOverlay() {
  if (closer) { closer(); closer = null; }
}

/** Escape has two meanings; this is how the caller tells them apart. */
export const overlayOpen = () => closer !== null;

function overlay(title, build, { onClose } = {}) {
  closeOverlay();
  const back = el('div', 'overlay');
  const card = el('div', 'card');
  const head = el('div', 'card-head');
  head.append(el('h3', null, title));
  const x = el('button', 'x', '×');
  head.append(x);
  card.append(head);

  const body = el('div', 'card-body');
  build(body);
  card.append(body);
  back.append(card);
  document.body.append(back);

  const shut = () => { back.remove(); document.removeEventListener('keydown', onKey); onClose?.(); };
  // stopPropagation matters: this listener is on document, the app's Escape
  // handler is on window, and document bubbles to window. Without it one
  // press closed the overlay AND walked the player out of the fight.
  const onKey = (e) => {
    if (e.key !== 'Escape') return;
    e.stopPropagation();
    closeOverlay();
  };
  document.addEventListener('keydown', onKey);
  x.addEventListener('click', () => closeOverlay());
  back.addEventListener('click', (e) => { if (e.target === back) closeOverlay(); });

  closer = shut;
  return { body, close: () => closeOverlay() };
}

/**
 * Hints, one at a time, and never more than the floor has.
 * Ports Show-Hints (engine/Adventure.ps1:738).
 */
export function showHints({ level, progress, onChange }) {
  const draw = (body) => {
    body.replaceChildren();
    const seen = hintsSeen(progress, level);
    const total = level.hints.length;

    if (seen === 0) body.append(el('p', 'dim', 'The tower will whisper, but only if you ask.'));

    for (let i = 0; i < seen && i < total; i++) {
      const h = el('div', 'hint');
      h.append(el('div', 'hint-n', `whisper ${i + 1} of ${total}`));
      h.append(inlineCode(level.hints[i]));
      body.append(h);
    }

    const more = el('button', 'wide');
    if (seen >= total) {
      more.textContent = 'no whispers left';
      more.disabled = true;
      body.append(more);
      body.append(el('p', 'dim', 'Reading the answer is allowed - but retype it, do not paste it.'));
    } else {
      more.textContent = seen === 0 ? 'ask for a whisper' : 'ask for another';
      more.addEventListener('click', () => { seeHint(progress, level); onChange?.(); draw(body); });
      body.append(more);
    }
  };

  overlay(`floor ${level.number} - whispers`, draw);
}

/** `code` spans inside a hint, the same markers the briefs use. */
function inlineCode(text) {
  const p = el('p');
  for (const part of String(text).split(/(`[^`]+`)/g)) {
    if (!part) continue;
    if (part.startsWith('`') && part.endsWith('`')) p.append(el('code', null, part.slice(1, -1)));
    else p.append(document.createTextNode(part));
  }
  return p;
}

/** Ports Show-Answer (engine/Adventure.ps1:825). */
export function showAnswer({ level }) {
  overlay(`floor ${level.number} - the answer`, (body) => {
    body.append(el('p', 'warn',
      'Reading the answer is allowed - but retype it, do not paste it.'));
    for (const file of level.solution) {
      body.append(el('div', 'file-name', file.name));
      const pre = el('pre');
      pre.append(el('code', null, file.contents));
      body.append(pre);
    }
  });
}

/**
 * The guardian falls. Ports Invoke-Victory (engine/Adventure.ps1:871),
 * including counting the XP up so it feels earned.
 */
export function showVictory({ level, award, bundle, onNext, onTower }) {
  overlay(level.boss ? 'BOSS FLOOR CLEARED' : 'FLOOR CLEARED', (body) => {
    body.classList.add('victory');
    body.append(el('div', 'big', level.title));

    const art = el('pre', 'art broken', guardianFor(level).art.join('\n'));
    body.append(art);

    body.append(el('div', 'gained', award.first ? `+${level.xp} XP` : 'already cleared'));

    const xpEl = el('div', 'xpcount', `${award.oldXp} XP`);
    body.append(xpEl);

    const bar = el('span', 'bar');
    const fill = el('i');
    fill.style.width = `${(award.oldXp / bundle.totalXp) * 100}%`;
    bar.append(fill);
    body.append(bar);

    if (award.rankChanged) body.append(el('div', 'newrank', `New rank: ${award.newRank}`));

    const buttons = el('div', 'buttons');
    if (onNext) {
      const b = el('button', 'primary', 'the next floor');
      b.addEventListener('click', () => { closeOverlay(); onNext(); });
      buttons.append(b);
    }
    const t = el('button', null, 'back to the tower');
    t.addEventListener('click', () => { closeOverlay(); onTower(); });
    buttons.append(t);
    body.append(buttons);

    // Count it up, so it reads as something that was earned.
    if (award.first && award.newXp > award.oldXp) {
      const steps = 24;
      let s = 0;
      const tick = () => {
        s++;
        const shown = Math.round(award.oldXp + (award.newXp - award.oldXp) * (s / steps));
        xpEl.textContent = `${shown} XP`;
        fill.style.width = `${(shown / bundle.totalXp) * 100}%`;
        if (s < steps) requestAnimationFrame(tick);
      };
      requestAnimationFrame(tick);
    }
  });
}

/** Ports Invoke-Ending (engine/Adventure.ps1:944). */
export function showEnding({ onTower }) {
  overlay('the roof', (body) => {
    body.classList.add('ending');
    body.append(el('div', 'big', 'T H E   C L I M B   I S   D O N E'));
    body.append(el('p', null, 'Twenty-five floors. Every one of them compiled.'));
    body.append(el('p', 'dim',
      'On floor 25 there is a game with a dungeon, monsters, loot, a locked door '
      + 'and a save file. You wrote all of it.'));
    body.append(el('p', 'cyan', 'Now open an empty folder and build the next one.'));
    const b = el('button', 'primary', 'back to the tower');
    b.addEventListener('click', () => { closeOverlay(); onTower(); });
    body.append(b);
  });
}
