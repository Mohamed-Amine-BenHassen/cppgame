/*
 * editor.js - the code pane: CodeMirror 6, file tabs, and a symbol row.
 *
 * Three things here exist purely because this is a tablet:
 *
 *   1. autocapitalize / autocorrect / spellcheck are all off. A tablet
 *      keyboard will happily capitalise every line and "fix" identifiers,
 *      and the trials compare character for character.
 *   2. a symbol row, because { } ; << and " are buried two taps deep on an
 *      on-screen keyboard and C++ is made of them.
 *   3. line wrapping, because there is no horizontal room to spare.
 *
 * Each file keeps its own EditorState, so switching tabs on floors 19 and
 * 21-25 preserves the cursor and the undo history for every file.
 */
import { EditorView, keymap, lineNumbers, highlightActiveLine, highlightActiveLineGutter } from '@codemirror/view';
import { EditorState } from '@codemirror/state';
import { cpp } from '@codemirror/lang-cpp';
import { defaultKeymap, history, historyKeymap, indentWithTab } from '@codemirror/commands';
import { syntaxHighlighting, HighlightStyle, indentUnit, bracketMatching } from '@codemirror/language';
import { tags as t } from '@lezer/highlight';

/* The palette is the terminal game's, so both versions look like one game.
 * Values mirror the ANSI table in engine/Screen.ps1:18-32. */
const theme = EditorView.theme({
  '&': { color: '#c8d3e4', backgroundColor: '#161b25', height: '100%' },
  '.cm-content': {
    caretColor: '#35c7d4',
    fontFamily: 'ui-monospace, "Cascadia Code", "SF Mono", Menlo, Consolas, monospace',
    fontSize: '13px',
    lineHeight: '1.6',
    padding: '10px 0',
    /* No ligatures. Cascadia and friends draw <= as a single glyph and -> as
     * an arrow; in a game teaching exact C++ syntax that is a lie about what
     * the player typed, and what they have to type. */
    fontVariantLigatures: 'none',
  },
  '.cm-cursor, .cm-dropCursor': { borderLeftColor: '#35c7d4', borderLeftWidth: '2px' },
  '&.cm-focused .cm-selectionBackground, .cm-selectionBackground, ::selection':
    { backgroundColor: '#2b3f52' },
  '.cm-gutters': { backgroundColor: '#10131a', color: '#46506a', border: 'none' },
  '.cm-activeLine': { backgroundColor: '#1b2230' },
  '.cm-activeLineGutter': { backgroundColor: '#1b2230', color: '#6b7890' },
  '.cm-matchingBracket, &.cm-focused .cm-matchingBracket':
    { backgroundColor: '#2f4a4d', color: '#a6ecf2', outline: 'none' },
  '.cm-scroller': { overflow: 'auto' },
}, { dark: true });

const highlight = HighlightStyle.define([
  { tag: [t.keyword, t.modifier, t.controlKeyword], color: '#b98ad4' },
  { tag: [t.typeName, t.className, t.standard(t.typeName)], color: '#35c7d4' },
  { tag: [t.function(t.variableName), t.function(t.propertyName)], color: '#96d45c' },
  { tag: [t.string, t.special(t.string)], color: '#d9b45c' },
  { tag: [t.number, t.bool, t.null], color: '#e2a05f' },
  { tag: [t.comment, t.lineComment, t.blockComment], color: '#5c6880', fontStyle: 'italic' },
  { tag: [t.meta, t.processingInstruction], color: '#6fb3c4' },
  { tag: [t.operator, t.punctuation, t.separator], color: '#8c9ab5' },
  { tag: t.variableName, color: '#c8d3e4' },
]);

/* Every one of these is awkward on an on-screen keyboard and constant in C++.
 * `label` is what the key shows; `insert` is what it types; `back` moves the
 * caret back that many characters so a pair lands you inside it. */
const SYMBOLS = [
  { label: '{', insert: '{}', back: 1 },
  { label: '}', insert: '}' },
  { label: ';', insert: ';' },
  { label: '<<', insert: ' << ' },
  { label: '>>', insert: ' >> ' },
  { label: '"', insert: '""', back: 1 },
  { label: '( )', insert: '()', back: 1 },
  { label: '[ ]', insert: '[]', back: 1 },
  { label: '::', insert: '::' },
  { label: '->', insert: '->' },
  { label: '&', insert: '&' },
  { label: '#', insert: '#' },
  { label: '\\n', insert: '\\n' },
  { label: 'TAB', insert: '    ' },
];

/**
 * @param {object} opts
 * @param {HTMLElement} opts.mount     container; it is emptied and owned
 * @param {() => void} [opts.onStrike] Ctrl/Cmd+S inside the editor
 * @param {() => void} [opts.onChange]
 */
export function createEditor({ mount, onStrike = () => {}, onChange = () => {} }) {
  mount.replaceChildren();
  mount.classList.add('editor');

  const tabs = document.createElement('div');
  tabs.className = 'editor-tabs';

  const host = document.createElement('div');
  host.className = 'editor-host';

  const row = document.createElement('div');
  row.className = 'symbol-row';

  mount.append(tabs, host, row);

  /** @type {Map<string, EditorState>} one state per file, so undo survives tab switches */
  const states = new Map();
  let order = [];
  let active = null;

  function extensions() {
    return [
      lineNumbers(),
      highlightActiveLine(),
      highlightActiveLineGutter(),
      history(),
      bracketMatching(),
      cpp(),
      syntaxHighlighting(highlight),
      theme,
      EditorView.lineWrapping,
      indentUnit.of('    '),
      EditorState.tabSize.of(4),
      keymap.of([
        { key: 'Mod-s', preventDefault: true, run: () => { onStrike(); return true; } },
        indentWithTab,
        ...historyKeymap,
        ...defaultKeymap,
      ]),
      // The attributes that stop a tablet keyboard sabotaging the code.
      EditorView.contentAttributes.of({
        autocapitalize: 'off',
        autocorrect: 'off',
        autocomplete: 'off',
        spellcheck: 'false',
      }),
      EditorView.updateListener.of((u) => {
        if (!u.docChanged) return;
        if (active) states.set(active, view.state);
        onChange();
      }),
    ];
  }

  const view = new EditorView({
    parent: host,
    state: EditorState.create({ doc: '', extensions: extensions() }),
  });

  function drawTabs() {
    tabs.replaceChildren();
    // One file needs no tab strip; floors 19 and 21-25 do.
    tabs.style.display = order.length > 1 ? 'flex' : 'none';
    for (const name of order) {
      const b = document.createElement('button');
      b.type = 'button';
      b.className = 'tab' + (name === active ? ' on' : '');
      b.textContent = name;
      b.addEventListener('click', () => select(name));
      tabs.append(b);
    }
  }

  function select(name) {
    if (!states.has(name)) return;
    if (active) states.set(active, view.state);
    active = name;
    view.setState(states.get(name));
    drawTabs();
    view.focus();
  }

  for (const sym of SYMBOLS) {
    const b = document.createElement('button');
    b.type = 'button';
    b.className = 'sym';
    b.textContent = sym.label;
    // Keep the on-screen keyboard up: a plain click would blur the editor.
    b.addEventListener('pointerdown', (e) => {
      e.preventDefault();
      const at = view.state.selection.main;
      view.dispatch({
        changes: { from: at.from, to: at.to, insert: sym.insert },
        selection: { anchor: at.from + sym.insert.length - (sym.back ?? 0) },
        scrollIntoView: true,
      });
      view.focus();
    });
    row.append(b);
  }

  return {
    /** @param {{name:string,contents:string}[]} files */
    setFiles(files) {
      states.clear();
      order = files.map((f) => f.name);
      for (const f of files) {
        states.set(f.name, EditorState.create({ doc: f.contents, extensions: extensions() }));
      }
      // Open where the work is: main.cpp if the floor has one, otherwise the
      // first .cpp - never a header, and never just whatever sorts first.
      active = order.find((n) => n === 'main.cpp')
        ?? order.find((n) => n.endsWith('.cpp'))
        ?? order[0] ?? null;
      if (active) view.setState(states.get(active));
      drawTabs();
    },

    /** Current contents of every file, in their original order. */
    getFiles() {
      if (active) states.set(active, view.state);
      return order.map((name) => ({ name, contents: states.get(name).doc.toString() }));
    },

    get activeName() { return active; },
    focus() { view.focus(); },
    destroy() { view.destroy(); },
  };
}
