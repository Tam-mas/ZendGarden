// Optional browser regression: run after build_web.py with serve_web.py running.
// PLAYWRIGHT_MODULE can point at an existing Playwright installation.
const assert = require('node:assert/strict');
const {chromium, webkit} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
(async () => {
 for (const [name, engine] of [['webkit',webkit],['chromium',chromium]]) {
  const browser=await engine.launch({headless:true,...(name==='chromium'?{channel:'chrome'}:{})});
  const ctx=await browser.newContext({ignoreHTTPSErrors:process.env.LOCAL_TEST_CERT==='1',hasTouch:true,isMobile:true,viewport:{width:1024,height:700}});
  const page=await ctx.newPage();
  const errors=[];
  page.on('requestfailed',r=>errors.push(`${r.url()}: ${r.failure()?.errorText}`));
  page.on('pageerror',e=>errors.push(e.message));
  await page.goto(process.env.TEST_URL || 'http://localhost:8080');
  for (const [width,height] of [[1024,700],[768,960],[844,390],[390,740]]) {
   await page.setViewportSize({width,height});
   await page.waitForTimeout(200);
   await page.locator('#play').scrollIntoViewIfNeeded();
   const boxes=await page.evaluate(()=>{
    const rect=id=>{const r=document.getElementById(id).getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height,bottom:r.bottom};};
    return {welcome:rect('welcome'),canvas:rect('canvas'),play:rect('play'),width:visualViewport.width,height:visualViewport.height};
   });
   assert(Math.abs(boxes.welcome.y)<2 && Math.abs(boxes.welcome.h-boxes.height)<2,`${name}: overlay escaped viewport`);
   assert(Math.abs(boxes.canvas.y)<2 && Math.abs(boxes.canvas.h-boxes.height)<2,`${name}: canvas escaped viewport`);
   assert(Math.abs(boxes.canvas.w-boxes.width)<2,`${name}: canvas kept old orientation width`);
   assert(boxes.play.y>=0 && boxes.play.bottom<=boxes.height,`${name}: Enter button unreachable`);
   assert.deepEqual(errors,[]);
   await page.screenshot({path:`/tmp/zend-${name}-${width}x${height}.png`});
  }
  // Fullscreen denial must leave a usable launch screen, not block entry.
  await page.evaluate(()=>{document.documentElement.requestFullscreen=()=>Promise.reject(new Error('Denied for test'));});
  const button=page.locator('#fullscreen');
  if(await button.isVisible()) {
   await button.click();
   await page.waitForFunction(()=>document.getElementById('fullscreen-note').textContent.includes('still fill'));
   assert(await page.locator('#play').isEnabled());
  }
  console.log(`VIEWPORT_RESULT ${name}: PASS — tablet, phone, rotation, reachable entry and fullscreen fallback`);
  await browser.close();
 }
})().catch(e=>{console.error(e);process.exit(1);});
