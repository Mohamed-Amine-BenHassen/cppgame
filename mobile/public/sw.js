/*
 * sw.js - what makes the tower work with no network at all.
 *
 * Two caches, because the two halves age completely differently:
 *
 *   tot-shell      the app itself - small, changes whenever I rebuild
 *   tot-toolchain  clang, lld, memfs, sysroot - 58 MB, and immutable
 *
 * The toolchain is cache-first and never revalidated: those five files are
 * pinned upstream releases, and re-fetching 58 MB to be told nothing changed
 * would be the single rudest thing this app could do to a tablet on mobile
 * data. The shell is network-first so a rebuild is picked up next launch,
 * falling back to cache the moment the network is not there.
 */
const SHELL = 'tot-shell-v1';
const TOOLCHAIN = 'tot-toolchain-v1';
const KEEP = [SHELL, TOOLCHAIN];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(SHELL);
    // Everything else arrives through fetch; this is just enough to boot.
    await cache.addAll(['/', '/index.html', '/manifest.webmanifest', '/icon.svg']).catch(() => {});
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const name of await caches.keys()) {
      if (!KEEP.includes(name)) await caches.delete(name);
    }
    await self.clients.claim();
  })());
});

const isToolchain = (url) => url.pathname.startsWith('/wasm-clang/');
const isAsset = (url) => url.pathname.startsWith('/assets/') || /\.(png|svg|webmanifest)$/.test(url.pathname);

self.addEventListener('fetch', (event) => {
  const { request } = event;
  if (request.method !== 'GET') return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  // The compiler: cache-first, forever.
  if (isToolchain(url)) {
    event.respondWith((async () => {
      const cache = await caches.open(TOOLCHAIN);
      const hit = await cache.match(request);
      if (hit) return hit;
      const res = await fetch(request);
      // A partial or failed download must not be cached, or the toolchain is
      // permanently broken with no obvious way for the player to fix it.
      if (res.ok && res.status === 200) cache.put(request, res.clone());
      return res;
    })());
    return;
  }

  // Build output is content-hashed, so it is safe to serve from cache first.
  if (isAsset(url)) {
    event.respondWith((async () => {
      const cache = await caches.open(SHELL);
      const hit = await cache.match(request);
      if (hit) return hit;
      const res = await fetch(request);
      if (res.ok) cache.put(request, res.clone());
      return res;
    })());
    return;
  }

  // Pages: fresh if we can, cached if we cannot.
  event.respondWith((async () => {
    const cache = await caches.open(SHELL);
    try {
      const res = await fetch(request);
      if (res.ok) cache.put(request, res.clone());
      return res;
    } catch {
      return (await cache.match(request))
        ?? (await cache.match('/index.html'))
        ?? Response.error();
    }
  })());
});
