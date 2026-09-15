/*
 * make-icons.mjs - draws the home-screen icons.
 *
 *   node mobile/tools/make-icons.mjs
 *
 * A PWA needs real PNGs (iOS will not take an SVG for apple-touch-icon), and
 * pulling in an image library to draw a tower out of five rectangles would be
 * silly. So: paint into a pixel buffer, then encode a PNG by hand with the
 * zlib that ships with node.
 *
 * Re-run only when the artwork changes; the output is committed.
 */
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

const OUT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'public');

const BG = [0x10, 0x13, 0x1a];
const STONE = [0x35, 0xc7, 0xd4];
const DOOR = [0xd9, 0xb4, 0x5c];
const DEEP = [0x1d, 0x3a, 0x44];

/* The tower, in fractions of the icon so it scales to any size. */
function shade(u, v) {
  const band = (a, b) => v >= a && v < b;
  const span = (a, b) => u >= a && u < b;

  // battlements: three merlons with two gaps
  if (band(0.20, 0.30) && (span(0.32, 0.42) || span(0.45, 0.55) || span(0.58, 0.68))) return STONE;
  // body
  if (band(0.30, 0.84) && span(0.32, 0.68)) {
    if (band(0.36, 0.46) && span(0.46, 0.54)) return DEEP;   // window
    if (band(0.60, 0.84) && span(0.44, 0.56)) return DOOR;   // door
    return STONE;
  }
  // plinth
  if (band(0.84, 0.89) && span(0.26, 0.74)) return STONE;
  return BG;
}

const table = new Int32Array(256);
for (let n = 0; n < 256; n++) {
  let c = n;
  for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
  table[n] = c;
}
const crc = (buf) => {
  let c = 0xffffffff;
  for (const byte of buf) c = table[(c ^ byte) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
};
const chunk = (type, data) => {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length);
  const body = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const tail = Buffer.alloc(4);
  tail.writeUInt32BE(crc(body));
  return Buffer.concat([len, body, tail]);
};

function png(size) {
  const stride = size * 3 + 1;                 // one filter byte per row
  const raw = Buffer.alloc(stride * size);
  for (let y = 0; y < size; y++) {
    raw[y * stride] = 0;                       // filter: none
    for (let x = 0; x < size; x++) {
      const [r, g, b] = shade((x + 0.5) / size, (y + 0.5) / size);
      const at = y * stride + 1 + x * 3;
      raw[at] = r; raw[at + 1] = g; raw[at + 2] = b;
    }
  }

  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(size, 0);
  ihdr.writeUInt32BE(size, 4);
  ihdr[8] = 8;        // bit depth
  ihdr[9] = 2;        // colour type: truecolour
  return Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
}

fs.mkdirSync(OUT, { recursive: true });
for (const size of [192, 512]) {
  const file = path.join(OUT, `icon-${size}.png`);
  fs.writeFileSync(file, png(size));
  console.log(`  icon-${size}.png  ${(fs.statSync(file).size / 1024).toFixed(1)} KB`);
}

/* The same drawing as vector, for the browser tab. */
const rects = [
  [0.32, 0.20, 0.10, 0.10], [0.45, 0.20, 0.10, 0.10], [0.58, 0.20, 0.10, 0.10],
  [0.32, 0.30, 0.36, 0.54], [0.26, 0.84, 0.48, 0.05],
];
const svg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" fill="#10131a"/>
  ${rects.map(([x, y, w, h]) =>
    `<rect x="${x * 100}" y="${y * 100}" width="${w * 100}" height="${h * 100}" fill="#35c7d4"/>`).join('\n  ')}
  <rect x="46" y="36" width="8" height="10" fill="#1d3a44"/>
  <rect x="44" y="60" width="12" height="24" fill="#d9b45c"/>
</svg>
`;
fs.writeFileSync(path.join(OUT, 'icon.svg'), svg);
console.log('  icon.svg');
