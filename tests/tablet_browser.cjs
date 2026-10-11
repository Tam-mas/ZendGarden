// Optional real-game check after tools/build_web.py. All requests and saves are
// isolated fixtures; this never sends analytics or touches a player's garden.
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const HOME = 'https://zend.garden';
const SAVE = '/userfs/godot/app_userdata/Zend Garden/garden_v1.json';
(async () => {
 const browser = await chromium.launch({headless:true, channel:'chrome'});
 try {
  const context = await browser.newContext({hasTouch:true, isMobile:true, viewport:{width:1024,height:768}});
  const errors = [], sessions = [];
  const version = Number((await fs.readFile('scripts/player_updates.gd','utf8')).match(/"version":(\d+)/)[1]);
  await context.route('**/*', async route => {
   const url = new URL(route.request().url());
   if (url.origin !== HOME) return route.abort();
   if (url.pathname === '/fixture') return route.fulfill({contentType:'text/html',body:'<!doctype html><body>Fixture</body>'});
   if (url.pathname === '/api/session') {
    const packet = route.request().postDataJSON(); sessions.push(packet);
    return route.fulfill({json:packet.action === 'start' ? {token:'fixture'} : {ok:true}});
   }
   const filename = path.resolve('build/web', '.' + (url.pathname === '/' ? '/index.html' : url.pathname));
   if (!filename.startsWith(path.resolve('build/web') + path.sep)) return route.abort();
   try {
    const body = await fs.readFile(filename);
    const contentType = {'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm','.json':'application/json','.css':'text/css','.png':'image/png','.webp':'image/webp'}[path.extname(filename)] || 'application/octet-stream';
    const headers = url.pathname === '/' ? {'Content-Security-Policy':"default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self'; worker-src 'self' blob:; media-src 'self' blob:"} : {};
    return route.fulfill({body, contentType, headers});
   } catch {return route.fulfill({status:404,body:'Missing fixture asset'});}
  });
  const page = await context.newPage();
  page.on('pageerror', error => errors.push(error.message));
  page.on('console', message => {if (/SCRIPT ERROR|ERROR:|EvalError/.test(message.text())) errors.push(message.text());});
  await page.goto(HOME + '/fixture');
  await page.evaluate(async ({SAVE,version}) => {
   const data = {version:2,day:1,clock:.3,coins:200,plants:[],objects:[],unlocked_plants:[0,1,2],names:['Miso','Clover'],settings:{intro_seen:true,updates_seen:version,controls:'auto',graphics:'mobile',music_volume:0,request_notifications:false}};
   data.inventory=Object.fromEntries(Array.from({length:25},(_,id)=>[String(id),4]));
   await new Promise((resolve,reject) => {
    const request = indexedDB.open('/userfs',21);
    request.onupgradeneeded = () => {const store=request.result.createObjectStore('FILE_DATA');store.createIndex('timestamp','timestamp');};
    request.onsuccess = () => {
     const db=request.result, tx=db.transaction('FILE_DATA','readwrite'), store=tx.objectStore('FILE_DATA'), timestamp=new Date();
     for (const dir of ['/userfs/godot','/userfs/godot/app_userdata','/userfs/godot/app_userdata/Zend Garden']) store.put({mode:0o40755,timestamp},dir);
     store.put({mode:0o100666,timestamp,contents:new TextEncoder().encode(JSON.stringify(data))},SAVE);
     tx.oncomplete=()=>{db.close();resolve();}; tx.onabort=()=>reject(tx.error);
    };
   });
  }, {SAVE,version});
  await page.goto(HOME + '/');
  await page.waitForFunction(() => window.ZendTelemetry);
  await page.evaluate(() => {
   const advance=window.ZendTelemetry.advance;
   window.ZendTelemetry.advance=seconds=>{window.tabletAdvanced=(window.tabletAdvanced||0)+seconds;advance(seconds);};
  });
  await page.getByRole('button',{name:'Enter the garden',exact:true}).click();
  await page.locator('#welcome').waitFor({state:'hidden',timeout:180000});
  await page.waitForFunction(() => window.tabletAdvanced > 0, {}, {timeout:90000});
  assert.equal(sessions.find(packet=>packet.action==='start').version,version);
  const capture=async name=>{await page.waitForTimeout(1000);await page.screenshot({path:path.resolve('captures/tablet-browser-'+name+'.png')});};
  const tap=async (x,y)=>{await page.touchscreen.tap(x,y);await page.waitForTimeout(1000);};
  const cdp=await context.newCDPSession(page);
  const swipe=async (x,y,endY) => {
   await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{id:7,x,y}]});
   for(let step=1;step<=8;step++) {
    await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{id:7,x,y:y+(endY-y)*step/8}]});
    await page.waitForTimeout(25);
   }
   await page.waitForTimeout(180); // Settle before release so this check has no flick momentum.
   await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
   await page.waitForTimeout(500);
  };
  const paused=async () => {
   await page.waitForTimeout(1500);
   const before=await page.evaluate(()=>window.tabletAdvanced);
   await page.waitForTimeout(2000);
   assert.equal(await page.evaluate(()=>window.tabletAdvanced),before,'Touch menu must pause the garden clock');
  };
  await capture('wide-garden');
  await tap(60,588); // Seeds, above movement.
  await paused();
  await capture('wide-seeds');
  await tap(115,204); // The main dropdown includes plant types and personal views.
  await capture('quick-types');
  await tap(110,282); // Flowers in the open dropdown.
  await capture('quick-flowers');
  await tap(115,204);
  await tap(110,255); // All plants again.
  await page.waitForTimeout(500);
  const menuClip={x:26,y:142,width:350,height:360};
  const unscrolled=await page.screenshot({clip:menuClip});
  await swipe(130,480,360); // Start on the card itself, away from the scrollbar.
  await paused();
  assert.notDeepEqual(await page.screenshot({clip:menuClip}),unscrolled,'Swiping a plant image must move the list');
  await capture('swiped-seeds');
  await swipe(130,350,690); // Return to the top; no accidental card selection.
  await tap(267,102); // Orders.
  await tap(175,151); // Basket.
  const basketBefore=await page.screenshot({clip:menuClip});
  await swipe(170,480,320); // Scroll the harvest pictures/text, not the scrollbar.
  await paused();
  assert.notDeepEqual(await page.screenshot({clip:menuClip}),basketBefore,'Swiping basket contents must move the list');
  await capture('swiped-basket');
  await tap(70,102); // Back to Seeds at the top.
  await tap(130,450); // First seed card opens its details.
  await capture('wide-details');
  const before=await page.evaluate(()=>window.tabletAdvanced);
  await tap(200,325); // The large plant image is also a direct planting action.
  await page.waitForFunction(value=>window.tabletAdvanced>value,before,{timeout:90000});
  await capture('wide-planting');
  await tap(180,588); // Current tool opens compact tray.
  await paused();
  await capture('wide-tools');
  await tap(405,315); // Water in the upper-right tray cell.
  await capture('wide-watering');
  // The browser must forward both fingers, including action-thumb camera drag.
  const points=(x,y)=>[{id:1,x:80,y:665},{id:2,x,y}];
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{id:2,x:800,y:300}]});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{id:2,x:800,y:440}]});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:points(924,588)});
  await page.waitForTimeout(600);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:points(904,588)});
  await page.waitForTimeout(600);
  await cdp.send('Input.dispatchTouchEvent',{type:'touchCancel',touchPoints:[]});
  await capture('two-thumbs');
  await tap(952,46); // Guide opens help and expandable garden actions.
  await paused();
  await page.setViewportSize({width:800,height:740});
  await capture('square-garden-menu');
  await tap(70,102); // Seeds tab below the title and utility icons.
  await capture('square-seeds');
  await page.setViewportSize({width:768,height:1024});
  await capture('portrait-seeds');
  await paused();
  await tap(170,101); // Shop: Decor, Equipment, Tools, Bed care.
  await tap(252,151);
  await capture('portrait-tool-cards');
  await tap(155,151);
  await capture('portrait-equipment');
  await tap(348,52); // Settings gear, at the top right of the left sidebar.
  await tap(120,151); // Expand Sound below its category heading.
  await capture('portrait-settings');
  await paused();
  const resumed=await page.evaluate(()=>window.tabletAdvanced);
  await tap(397,52); // Close icon returns to gardening.
  await page.waitForFunction(value=>window.tabletAdvanced>value,resumed,{timeout:90000});
  assert.deepEqual(errors,[]);
  assert.equal(await page.evaluate(()=>document.pointerLockElement),null,'Touch must never require pointer lock');
  console.log('TABLET_BROWSER_RESULT: PASS — card swipe scrolling, portrait-tap planting, real touch entry, tool tray, paused menus, two-finger dispatch, square and portrait rotation, strict CSP');
  await context.close();
 } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
