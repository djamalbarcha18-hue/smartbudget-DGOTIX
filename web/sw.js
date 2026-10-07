// SmartBudget offline support: keeps the app in the browser so it opens and
// works with no internet. The deploy (.github/workflows/deploy-web.yml) writes
// the build id and the Flutter engine revision below.
//
//   - The page (index.html) comes from the network when possible, else from
//     the cache: an online user always gets the latest deploy.
//   - This build's code (main.dart.js?v=<build>, ...) is stored when the
//     service worker installs; the rendering engine (canvaskit/) is stored per
//     engine revision, so a deploy with the same Flutter keeps it.
//   - The app's assets (fonts, images) are stored at install; they and other
//     files of the site are served from the cache and refreshed in the
//     background. Google's font files are stored on first use.
//   - build.json (the update check) and every other service (Supabase, AI,
//     exchange rates...) always go to the network: the app handles being
//     offline for those itself.
const BUILD = 'dev';
const ENGINE = 'dev';
// Every file under assets/ (fonts, logos, flags: about 1.5 MB), written by
// the deploy; each is stored once and refreshed in the background.
const ASSETS = [];

const SHELL = 'sb-shell-' + BUILD;
const ENGINE_CACHE = 'sb-engine-' + ENGINE;
const RUNTIME = 'sb-runtime-v1';
const FONT_HOSTS = ['fonts.gstatic.com', 'fonts.googleapis.com'];

const versioned = (f) => (BUILD === 'dev' ? f : f + '?v=' + BUILD);

const SHELL_FILES = [
  './',
  versioned('flutter_bootstrap.js'),
  versioned('main.dart.js'),
  versioned('install_prompt.js'),
  versioned('offline.js'),
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'assets/FontManifest.json',
  'assets/AssetManifest.bin.json',
  'assets/fonts/MaterialIcons-Regular.otf',
];

// The engine variant Flutter picks: the Chromium build in Chrome-based
// browsers, the generic one elsewhere. Whichever is used is also stored on
// first use.
function engineFiles() {
  const ua = self.navigator.userAgent;
  const blink = /Chrome\/|Chromium\/|Edg\//.test(ua) && !/Firefox\//.test(ua);
  const dir = blink ? 'canvaskit/chromium/' : 'canvaskit/';
  return [dir + 'canvaskit.js', dir + 'canvaskit.wasm'];
}

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const shell = await caches.open(SHELL);
    await Promise.all(SHELL_FILES.map((f) =>
      shell.add(new Request(f, { cache: 'reload' })).catch(() => {})));
    const runtime = await caches.open(RUNTIME);
    await Promise.all(ASSETS.map(async (f) => {
      if (!(await runtime.match(f))) await runtime.add(f).catch(() => {});
    }));
    const engine = await caches.open(ENGINE_CACHE);
    await Promise.all(engineFiles().map(async (f) => {
      if (!(await engine.match(f))) await engine.add(f).catch(() => {});
    }));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const name of await caches.keys()) {
      const old = (name.startsWith('sb-shell-') && name !== SHELL) ||
        (name.startsWith('sb-engine-') && name !== ENGINE_CACHE);
      if (old) await caches.delete(name);
    }
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  if (url.origin !== self.location.origin) {
    if (FONT_HOSTS.includes(url.hostname)) {
      event.respondWith(cacheFirst(req, RUNTIME));
    }
    return; // Supabase, AI, rates, Cloudflare...: the network as usual.
  }

  const path = url.pathname.replace(/^.*\//, '');
  if (path === 'build.json' || path === 'sw.js') return;

  if (req.mode === 'navigate') {
    event.respondWith(page(req));
    return;
  }
  if (url.pathname.includes('/canvaskit/')) {
    event.respondWith(cacheFirst(req, ENGINE_CACHE));
    return;
  }
  if (url.searchParams.has('v')) {
    // A versioned file: only this build's is kept (older ones just pass).
    event.respondWith(url.searchParams.get('v') === BUILD
      ? cacheFirst(req, SHELL)
      : fetch(req));
    return;
  }
  event.respondWith(staleWhileRevalidate(req, RUNTIME));
});

// The page: network first (a few seconds), else the stored copy.
async function page(req) {
  const shell = await caches.open(SHELL);
  try {
    const res = await withTimeout(fetch(req), 4000);
    if (res.ok) shell.put('./', res.clone());
    return res;
  } catch (_) {
    return (await shell.match('./')) ||
      (await caches.match(req)) ||
      new Response('Offline', { status: 503 });
  }
}

async function cacheFirst(req, cacheName) {
  const hit = await caches.match(req, { ignoreVary: true });
  if (hit) return hit;
  const res = await fetch(req);
  if (res.ok || res.type === 'opaque') {
    const cache = await caches.open(cacheName);
    cache.put(req, res.clone());
  }
  return res;
}

async function staleWhileRevalidate(req, cacheName) {
  const cache = await caches.open(cacheName);
  // Whichever cache holds it (some files are stored at install).
  const hit = await caches.match(req, { ignoreVary: true });
  const refresh = fetch(req).then((res) => {
    if (res.ok) cache.put(req, res.clone());
    return res;
  }).catch(() => hit || new Response('', { status: 504 }));
  return hit || refresh;
}

function withTimeout(promise, ms) {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => reject(new Error('timeout')), ms);
    promise.then((v) => { clearTimeout(t); resolve(v); },
      (e) => { clearTimeout(t); reject(e); });
  });
}
