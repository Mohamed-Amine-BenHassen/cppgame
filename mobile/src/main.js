/*
 * main.js - the game.
 *
 * Two screens: the tower you walk, and the floor you fight on. Everything
 * else is an overlay. Mirrors the desktop state machine in
 * engine/Adventure.ps1 - tower, lesson, trial, victory, ending.
 */
import bundle from './content/levels.json';
import { createWorkerBackend } from './toolchain/worker-host.js';
import { runTrial, strikeLog, guardianFor } from './grader/trial.js';
import { createEditor } from './editor/editor.js';
import { renderMarkdown } from './ui/markdown.js';
import {
  renderTower, showHints, showAnswer, showVictory, showEnding, closeOverlay, overlayOpen,
} from './ui/screens.js';
import {
  loadProgress, saveProgress, completeLevel, registerAttempt,
  isDone, saveWork, loadWork, forgetWork, resetProgress,
} from './state/progress.js';

const $ = (id) => document.getElementById(id);
const els = {
  app: $('app'), tower: $('tower'), floor: $('floor'),
  back: $('back'), title: $('title'), status: $('status'),
  brief: $('brief'), editor: $('editor'), panes: $('panes'),
  art: $('art'), hp: $('hp'), bar: $('bar'), log: $('log'),
  strike: $('strike'), hint: $('hint'), answer: $('answer'), reset: $('reset'),
  boot: $('boot'), bootMsg: $('boot-msg'),
};

let progress = loadProgress();
let current = null;
let prevPassed = -1;
let busy = false;

const backend = createWorkerBackend({
  onStatus: (phase) => { if (busy) els.status.textContent = phase; },
});

const editor = createEditor({
  mount: els.editor,
  onStrike: () => strike(),
  onChange: () => {
    // Keep the player's code across reloads; the desktop has workspace\ for this.
    if (current) saveWork(progress, current, editor.getFiles());
  },
});

/* ------------------------------ screens ----------------------------- */

function toTower() {
  current = null;
  closeOverlay();
  document.body.dataset.screen = 'tower';
  els.title.textContent = 'TOWER OF TURING';
  els.status.textContent = `${progress.completed.length}/${bundle.levelCount} floors`;
  renderTower({ mount: els.tower, bundle, progress, onEnter: enterFloor });
  els.tower.scrollTop = 0;

  if (progress.completed.length === bundle.levelCount && !progress.sawEnding) {
    progress.sawEnding = true;
    saveProgress(progress);
    showEnding({ onTower: toTower });
  }
}

function enterFloor(level) {
  current = level;
  prevPassed = -1;
  document.body.dataset.screen = 'floor';
  document.body.dataset.pane = 'lesson';
  syncPanes();

  els.title.textContent = `${String(level.number).padStart(2, '0')}  ${level.title}`;
  els.status.textContent = isDone(progress, level) ? 'cleared' : `${level.xp} XP`;
  els.brief.replaceChildren(renderMarkdown(level.brief));
  els.brief.parentElement.scrollTop = 0;

  // Resume the player's own code if they have any, else the starter.
  editor.setFiles(loadWork(progress, level) ?? level.start);
  showGuardian(level);
  say([{ text: level.tagline, tone: 'dim' },
       { text: 'read the lesson, write the code, then strike.', tone: 'dim' }]);
}

/* ------------------------------- arena ------------------------------ */

function say(lines) {
  els.log.replaceChildren(...lines.flatMap(({ text, tone }) => {
    const span = document.createElement('span');
    span.className = tone ?? 'dim';
    span.textContent = text;
    return [span, document.createTextNode('\n')];
  }));
}

function showGuardian(level, passed = 0) {
  const g = guardianFor(level);
  const hp = level.tests.length;
  const left = Math.max(0, hp - passed);
  els.art.textContent = g.art.join('\n');
  els.art.style.color = g.color === 'magenta' ? 'var(--magenta)' : 'var(--cyan)';
  els.hp.textContent = `${g.name}  ${left}/${hp}`;
  els.bar.style.width = `${hp ? (left / hp) * 100 : 0}%`;
  els.bar.style.background = left === 0 ? 'var(--lime)' : 'var(--red)';
}

async function strike() {
  if (busy || !current) return;
  busy = true;
  els.strike.disabled = true;
  els.status.textContent = 'the runes glow...';
  const t0 = performance.now();

  try {
    const files = editor.getFiles();
    saveWork(progress, current, files);
    const result = await runTrial(current, files, backend, { ruleFlags: bundle.ruleRegexFlags });
    registerAttempt(progress, current);
    const secs = ((performance.now() - t0) / 1000).toFixed(1);

    showGuardian(current, result.passed);
    say([...strikeLog(result, prevPassed),
         { text: `\n${result.passed}/${result.total} trials   ${secs}s`, tone: 'dim' }]);
    prevPassed = result.passed;
    els.status.textContent = result.allPass ? 'the guardian falls' : 'ready';

    if (window.matchMedia('(max-width:900px)').matches) showPane('fight');

    if (result.allPass) {
      const cleared = current;
      const award = completeLevel(progress, cleared);
      const i = bundle.levels.indexOf(cleared);
      const next = bundle.levels[i + 1];
      setTimeout(() => showVictory({
        level: cleared, award, bundle,
        onNext: next ? () => enterFloor(next) : null,
        onTower: toTower,
      }), 450);
    }
  } catch (error) {
    say([{ text: `the tower itself broke: ${error.message}`, tone: 'red' }]);
    els.status.textContent = 'error';
  } finally {
    busy = false;
    els.strike.disabled = false;
  }
}

/* ------------------------------- panes ------------------------------ */

function showPane(name) {
  document.body.dataset.pane = name;
  syncPanes();
}
function syncPanes() {
  const active = document.body.dataset.pane;
  for (const b of els.panes.children) b.classList.toggle('on', b.dataset.pane === active);
}

/* ------------------------------ wiring ------------------------------ */

els.panes.addEventListener('click', (e) => {
  const b = e.target.closest('button');
  if (b) showPane(b.dataset.pane);
});
els.back.addEventListener('click', toTower);
els.strike.addEventListener('click', () => strike());
els.hint.addEventListener('click', () => {
  if (current) showHints({ level: current, progress, onChange: () => saveProgress(progress) });
});
els.answer.addEventListener('click', () => { if (current) showAnswer({ level: current }); });

els.reset.addEventListener('click', () => {
  if (!current) return;
  if (!confirm(`Restore floor ${current.number} to its starter code? Your work on it is lost.`)) return;
  forgetWork(progress, current);
  editor.setFiles(current.start);
  say([{ text: 'starter code restored.', tone: 'gold' }]);
});

window.addEventListener('keydown', (e) => {
  if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 's') { e.preventDefault(); strike(); }
  // Escape backs out one layer at a time: an open overlay first (the overlay
  // closes itself), and only then the floor. Without this check one press
  // dismissed a hint AND walked you out of the fight.
  else if (e.key === 'Escape' && !overlayOpen() && document.body.dataset.screen === 'floor') toTower();
});

/* ------------------------------- boot ------------------------------- */

// Ask the browser to keep the 58 MB toolchain rather than evict it.
if (navigator.storage?.persist) navigator.storage.persist().catch(() => {});

if ('serviceWorker' in navigator && import.meta.env.PROD) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js').catch(() => {});
  });
}

toTower();
els.boot?.remove();

if (import.meta.env.DEV) {
  window.__tot = {
    backend, bundle, editor, progress: () => progress,
    toTower, enterFloor, strike, resetAll: () => { progress = resetProgress(); toTower(); },
  };
}
