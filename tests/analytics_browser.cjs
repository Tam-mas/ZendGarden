// Isolated profiles and fixture saves only; never opens a player's browser data.
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const { createHash } = require('node:crypto');
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const HOME = 'https://garden.test';
const SAVE = '/userfs/godot/app_userdata/Zend Garden/garden_v1.json';
(async () => {
  const browser = await chromium.launch({ headless: true, channel: 'chrome' });
  const context = await browser.newContext({ viewport: { width: 1200, height: 900 } });
  const bytes = Buffer.from('GDPC fixture');
  const hash = createHash('sha256').update(bytes).digest('hex');
  const errors = [], metrics = [];
  const headers = { 'Content-Security-Policy': "default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self'; object-src 'none'; form-action 'none'" };
  const data = { generated: 1791590400, totals: { sessions: 12, running: 72000, advancing: 21000, average: 6000, median: 3000, longest: 18000, over5: 10, over15: 8, over30: 6, recent: 2 },
    daily: [{ day: '2026-10-10', sessions: 12, running: 72000, advancing: 21000 }],
    devices: [{ name: 'desktop', sessions: 8 }, { name: 'touch', sessions: 4 }],
    versions: [{ name: '63', sessions: 12, running: 72000, advancing: 21000 }] };
  try {
    await context.route(HOME + '/**', async route => {
      const url = new URL(route.request().url());
      const request = route.request();
      if (url.pathname === '/fixture') return route.fulfill({ body: '<!doctype html><body>Storage fixture</body>', contentType: 'text/html', headers });
      if (url.pathname === '/api/session') { metrics.push(request.postDataJSON()); return route.fulfill({ status: 503, body: '{}' }); }
      if (url.pathname === '/api/stats') return route.fulfill({ status: request.headers().authorization === 'Bearer owner-fixture-password' ? 200 : 401, json: data });
      if (url.pathname === '/index.js') return route.fulfill({ contentType: 'text/javascript', body: `class Engine {
        static getMissingFeatures(){return [];} async init(){} async preloadFile(){}
        async start(config){window.startArgs=config.args;window.ZendTelemetry?.setVersion(63);window.ZendSaveGuard.ready();}
      }` });
      if (url.pathname === '/godot-config.js') return route.fulfill({ contentType: 'text/javascript', body: 'window.ZEND_GODOT_CONFIG={};' });
      if (url.pathname === '/pack.json') return route.fulfill({ json: { size: bytes.length, chunks: [{ url: 'pack/fixture.bin', size: bytes.length, sha256: hash }] } });
      if (url.pathname === '/pack/fixture.bin') return route.fulfill({ body: bytes });
      let file = url.pathname === '/' ? 'shell.html' : url.pathname === '/stats' ? 'stats.html' : url.pathname.slice(1);
      try {
        let source = await fs.readFile(path.join('web', file));
        if (file === 'shell.html') source = source.toString().replace('$GODOT_HEAD_INCLUDE', '').replace('$GODOT_URL', 'index.js')
          .replace(/<script>window.ZEND_GODOT_CONFIG = \$GODOT_CONFIG;<\/script>/, '<script src="godot-config.js"></script>');
        return route.fulfill({ body: source, headers, contentType: { '.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.webp': 'image/webp', '.png': 'image/png' }[path.extname(file)] || 'application/octet-stream' });
      } catch { return route.fulfill({ status: 404, body: 'Missing fixture asset' }); }
    });
    const page = await context.newPage(); page.on('pageerror', error => errors.push(error.message));
    await page.goto(HOME + '/fixture');
    assert.equal(await page.evaluate(async () => (await import('/save-storage.js')).readCurrent()), null);
    assert.equal(await page.evaluate(async () => (await indexedDB.databases()).some(db => db.name === '/userfs')), false, 'Read guard must not create a filesystem');
    const original = { version: 3, day: 17, plants: [], names: ['Miso', 'Clover'], settings: { intro_seen: true },
      breeding: { forms: { 'form-1': { name: 'Misty petals' } } }, watered_ground: { '1:2': { x: 1, z: 2, radius: .6, until: 18 } } };
    const seed = async value => page.evaluate(async ({ SAVE, value }) => new Promise((resolve, reject) => {
      const request = indexedDB.open('/userfs', 21);
      request.onupgradeneeded = () => { request.result.createObjectStore('FILE_DATA').createIndex('timestamp', 'timestamp'); };
      request.onsuccess = () => {
        const db = request.result, tx = db.transaction('FILE_DATA', 'readwrite');
        tx.objectStore('FILE_DATA').put({ mode: 0o100666, timestamp: new Date(), contents: new TextEncoder().encode(JSON.stringify(value)) }, SAVE);
        tx.oncomplete = () => { db.close(); resolve(); }; tx.onabort = () => reject(tx.error);
      };
    }), { SAVE, value });
    await seed(original);
    const expected = createHash('sha256').update(JSON.stringify(original)).digest('hex');
    assert.equal(await page.evaluate(async () => { const session = await (await import('/save-storage.js')).beforeGameStart(); window.release = session.release; return session.expected; }), expected);
    const second = await context.newPage(); await second.goto(HOME + '/fixture');
    assert.match(await second.evaluate(async () => { try { await (await import('/save-storage.js')).beforeGameStart(); } catch (error) { return error.message; } }), /another tab/);
    await page.evaluate(() => window.release());
    await seed({ version: 4, plants: [] });
    assert.match(await page.evaluate(async () => { try { await (await import('/save-storage.js')).beforeGameStart(); } catch (error) { return error.message; } }), /safely/);
    await seed(original);
    await page.goto(HOME + '/');
    await page.getByRole('button', { name: 'Enter the garden', exact: true }).click();
    await page.locator('#welcome').waitFor({ state: 'hidden' });
    assert((await page.evaluate(() => window.startArgs)).includes('--browser-save-check=' + expected));
    await page.waitForTimeout(100);
    assert.equal(metrics[0].action, 'start'); assert.equal(metrics[0].version, 63);
    const restored = await page.evaluate(async () => JSON.parse(new TextDecoder().decode(await (await import('/save-storage.js')).readCurrent())));
    assert.deepEqual(restored, original, 'Migration removal must preserve exact ordinary save contents');
    await page.goto(HOME + '/stats');
    assert.equal(await page.locator('#dashboard').isVisible(), false);
    await page.locator('#password').fill('wrong'); await page.getByRole('button', { name: 'Open statistics' }).click();
    await page.getByText('That password was not recognised.').waitFor();
    await page.locator('#password').fill('owner-fixture-password'); await page.getByRole('button', { name: 'Open statistics' }).click();
    await page.locator('#dashboard').waitFor({ state: 'visible' });
    assert.match(await page.locator('#cards').textContent(), /20 h/);
    assert.equal(await page.locator('#password').inputValue(), '');
    assert.equal(await page.evaluate(() => localStorage.length + sessionStorage.length), 0);
    await page.screenshot({ path: '/private/tmp/zend-stats-desktop.png', fullPage: true });
    await page.setViewportSize({ width: 390, height: 844 });
    assert(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), 'Dashboard must fit a phone');
    await page.screenshot({ path: '/private/tmp/zend-stats-phone.png', fullPage: true });
    await page.getByRole('button', { name: 'Lock dashboard' }).click();
    assert.equal(await page.locator('#dashboard').isVisible(), false); assert.equal(await page.locator('#cards').textContent(), '');
    assert.deepEqual(errors, []);
    console.log('ANALYTICS_BROWSER_RESULT: PASS — real IndexedDB, exact saves, whole-session locks, corruption guard, loader with unavailable analytics, private dashboard, strict CSP and desktop/phone layouts');
  } finally { await context.close(); await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
