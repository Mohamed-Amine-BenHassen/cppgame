/*
 * markdown.js - renders a floor's brief.md.
 *
 * Covers exactly what the 25 briefs use and nothing more: headings, fenced
 * code, bullet and numbered lists, blockquotes, the odd table, plus `code`
 * and **bold** inline. Counted across levels/: 141 fences, 560 inline spans.
 *
 * It builds DOM nodes rather than an HTML string on purpose. The briefs are
 * full of std::vector<Monster>, << and &, and every one of those is a way to
 * corrupt a page assembled by concatenation. Text nodes cannot be mis-parsed.
 */

/** `code` and **bold**, applied to one line of prose. */
function inline(text, into) {
  // Split on the two markers at once so neither can swallow the other.
  const parts = text.split(/(`[^`]+`|\*\*[^*]+\*\*)/g);
  for (const part of parts) {
    if (!part) continue;
    if (part.startsWith('`') && part.endsWith('`') && part.length > 1) {
      const el = document.createElement('code');
      el.textContent = part.slice(1, -1);
      into.append(el);
    } else if (part.startsWith('**') && part.endsWith('**') && part.length > 3) {
      const el = document.createElement('strong');
      el.textContent = part.slice(2, -2);
      into.append(el);
    } else {
      into.append(document.createTextNode(part));
    }
  }
  return into;
}

const para = (lines) => inline(lines.join(' '), document.createElement('p'));

/**
 * @param {string} source  the raw brief.md
 * @returns {DocumentFragment}
 */
export function renderMarkdown(source) {
  const frag = document.createDocumentFragment();
  const lines = String(source ?? '').replace(/\r\n/g, '\n').split('\n');

  let i = 0;
  let buffer = [];                       // prose waiting to become a <p>

  const flush = () => {
    if (buffer.length) { frag.append(para(buffer)); buffer = []; }
  };

  while (i < lines.length) {
    const line = lines[i];

    // fenced code - taken verbatim, never interpreted
    if (line.trimStart().startsWith('```')) {
      flush();
      const body = [];
      i++;
      while (i < lines.length && !lines[i].trimStart().startsWith('```')) body.push(lines[i++]);
      i++;                                // closing fence
      const pre = document.createElement('pre');
      const code = document.createElement('code');
      code.textContent = body.join('\n');
      pre.append(code);
      frag.append(pre);
      continue;
    }

    const heading = line.match(/^(#{1,4})\s+(.*)$/);
    if (heading) {
      flush();
      const el = document.createElement(`h${heading[1].length}`);
      inline(heading[2], el);
      frag.append(el);
      i++;
      continue;
    }

    if (line.startsWith('>')) {
      flush();
      const body = [];
      while (i < lines.length && lines[i].startsWith('>')) {
        body.push(lines[i].replace(/^>\s?/, ''));
        i++;
      }
      const quote = document.createElement('blockquote');
      quote.append(para(body.filter((l) => l.trim())));
      frag.append(quote);
      continue;
    }

    // tables: | a | b |  with a |---|---| rule underneath
    if (line.trimStart().startsWith('|')) {
      flush();
      const rows = [];
      while (i < lines.length && lines[i].trimStart().startsWith('|')) rows.push(lines[i++]);
      const cells = (row) => row.trim().replace(/^\||\|$/g, '').split('|').map((c) => c.trim());
      const table = document.createElement('table');
      rows.forEach((row, idx) => {
        if (/^[\s|:-]+$/.test(row)) return;          // the |---|---| separator
        const tr = document.createElement('tr');
        for (const cell of cells(row)) {
          const td = document.createElement(idx === 0 ? 'th' : 'td');
          inline(cell, td);
          tr.append(td);
        }
        table.append(tr);
      });
      frag.append(table);
      continue;
    }

    const bullet = line.match(/^\s*[-*]\s+(.*)$/);
    const number = line.match(/^\s*\d+\.\s+(.*)$/);
    if (bullet || number) {
      flush();
      const list = document.createElement(bullet ? 'ul' : 'ol');
      const pattern = bullet ? /^\s*[-*]\s+(.*)$/ : /^\s*\d+\.\s+(.*)$/;
      while (i < lines.length) {
        const m = lines[i].match(pattern);
        if (!m) break;
        const li = document.createElement('li');
        inline(m[1], li);
        list.append(li);
        i++;
        // a wrapped continuation line belongs to the item above it
        while (i < lines.length && /^\s{2,}\S/.test(lines[i]) && !lines[i].match(pattern)) {
          li.append(document.createTextNode(' '));
          inline(lines[i].trim(), li);
          i++;
        }
      }
      frag.append(list);
      continue;
    }

    if (!line.trim()) { flush(); i++; continue; }

    buffer.push(line.trim());
    i++;
  }

  flush();
  return frag;
}
