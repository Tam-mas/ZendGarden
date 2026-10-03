// Real browser HTTP-cache regression. Uses tiny fixtures and isolated profiles.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const {gzipSync} = require('node:zlib');
const {createHash} = require('node:crypto');
const {chromium, webkit} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const current = Buffer.from('GDPC current game fixture');
const old = Buffer.alloc(current.length, 0x41);
const hash = createHash('sha256').update(current).digest('hex');
let updated = false, versioned = false;
let requests = [];
const server = http.createServer((req, res) => {
  requests.push(req.url);
  const url = new URL(req.url, 'http://localhost');
  if (url.pathname === '/fixture') {
    res.setHeader('Content-Type', 'text/html');
    res.end('<button id="play"></button><span id="status"></span><progress id="progress"></progress>');
  } else if (url.pathname === '/pack.json') {
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Cache-Control', 'no-cache');
    res.end(JSON.stringify({size:current.length, chunks:[{
      url:versioned ? `pack/000-${hash}.bin` : 'pack/000.bin', size:current.length, sha256:hash,
    }]}));
  } else if (url.pathname.startsWith('/pack/')) {
    res.setHeader('Content-Type', 'application/octet-stream');
    res.setHeader('Cache-Control', 'public, max-age=14400');
    res.end(gzipSync(updated ? current : old));
  } else { res.statusCode = 404; res.end(); }
});
(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const origin = `http://127.0.0.1:${server.address().port}`;
  try {
    for (const [name, engine] of [['Chrome', chromium], ['WebKit', webkit]]) {
      const browser = await engine.launch({headless:true, ...(name==='Chrome' ? {channel:'chrome'} : {})});
      try {
        const loaders = [['fixed', fs.readFileSync('web/loader.js', 'utf8')]];
        if (process.env.ZEND_OLD_LOADER) loaders.unshift(['old', fs.readFileSync(process.env.ZEND_OLD_LOADER, 'utf8')]);
        for (const [kind, loader] of loaders) {
          for (const hashed of [false, true]) {
            updated = false; versioned = hashed; requests = [];
            const context = await browser.newContext();
            try {
              const page = await context.newPage();
              await page.goto(origin+'/fixture');
              await page.evaluate(async () => (await fetch('/pack/000.bin')).arrayBuffer());
              updated = true;
              await page.addScriptTag({content:loader});
              const result = await page.evaluate(async () => {
                try { return {bytes:Array.from(new Uint8Array(await loadPack()))}; }
                catch (error) { return {error:error.message}; }
              });
              const oldRequests = requests.filter(url=>url==='/pack/000.bin').length;
              const cached = oldRequests === 1;
              if (name==='Chrome') assert(cached, 'Chrome must reuse the primed HTTP cache');
              if (kind==='old' && !hashed && cached) {
                assert.match(result.error, /download was incomplete/);
              } else {
                assert.deepEqual(Buffer.from(result.bytes), current);
                if (!hashed && cached) assert(requests.some(url => url===`/pack/000.bin?v=${hash}`));
              }
              // WebKit can choose to refetch rather than reuse this fixture's
              // cache. Verify its load too without claiming it reproduced stale bytes.
              assert(oldRequests<=2, 'Do not repeatedly redownload a piece');
              console.log(`BROWSER_LOADER_RESULT ${name} ${kind} ${hashed?'content URL':'old URL'} (${cached?'cache reused':'refetched'}): PASS`);
            } finally { await context.close(); }
          }
        }
      } finally { await browser.close(); }
    }
  } finally { await new Promise(resolve=>server.close(resolve)); }
})().catch(error=>{console.error(error);server.close();process.exitCode=1;});
