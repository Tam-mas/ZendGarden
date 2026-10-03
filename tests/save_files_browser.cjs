// Exercise real browser file selection under the production script policy.
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const {chromium, webkit} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
(async () => {
  const source = await fs.readFile('web/save-files.js');
  for (const [name, engine] of [['Chrome', chromium], ['WebKit', webkit]]) {
    const browser = await engine.launch({headless:true, ...(name==='Chrome'?{channel:'chrome'}:{})});
    try {
      const page = await browser.newPage();
      const errors = [];
      page.on('pageerror', error => errors.push(error.message));
      await page.route('https://garden.test/**', async route => {
        if (route.request().url().endsWith('/save-files.js')) {
          await route.fulfill({body:source,contentType:'text/javascript'});
        } else {
          await route.fulfill({body:'<button id="choose">Choose a garden save</button><script src="/save-files.js"></script>',contentType:'text/html',
            headers:{'Content-Security-Policy':"default-src 'self'; script-src 'self' 'wasm-unsafe-eval'"}});
        }
      });
      await page.goto('https://garden.test/');
      await page.evaluate(() => document.querySelector('#choose').onclick = () => {
        window.result = null;
        window.ZendSaveFiles.choose((text, name, error) => { window.result = {text, name, error}; });
      });
      const select = async (buffer, fileName='garden.json') => {
        const chooser = page.waitForEvent('filechooser');
        await page.click('#choose');
        await (await chooser).setFiles({name:fileName,mimeType:'application/json',buffer});
        await page.waitForFunction(() => window.result !== null);
        assert.equal(await page.locator('input[type=file]').count(),0,'Picker must clean up after selection');
        return page.evaluate(() => window.result);
      };
      for (const version of [1,2]) {
        const text=JSON.stringify({version,day:17,plants:[],extension:{kept:true}});
        assert.deepEqual(await select(Buffer.from(text),`garden-v${version}.json`),{text,name:`garden-v${version}.json`,error:''});
      }
      assert.match((await select(Buffer.alloc(4*1024*1024+1))).error,/4 MB/);
      assert.match((await select(Buffer.alloc(0))).error,/complete/);
      assert.match((await select(Buffer.from([0xff,0xfe,0x80]))).error,/could not be read/);
      const chooser=page.waitForEvent('filechooser');
      await page.click('#choose');
      await chooser;
      await page.evaluate(() => document.querySelector('input[type=file]').dispatchEvent(new Event('cancel')));
      assert.equal((await page.evaluate(() => window.result)).error,'cancelled');
      assert.equal(await page.locator('input[type=file]').count(),0);
      assert.deepEqual(errors,[]);
      console.log(`SAVE_FILES_BROWSER_RESULT ${name}: PASS — v1/v2 selection, exact text, limits, UTF-8 errors, cancellation and strict CSP`);
    } finally { await browser.close(); }
  }
})().catch(error => { console.error(error); process.exitCode=1; });
