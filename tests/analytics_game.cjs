// Real Godot web timing bridge, menus and an isolated existing garden save.
const assert=require('node:assert/strict');
const fs=require('node:fs/promises');
const path=require('node:path');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const HOME='https://zend.garden',SAVE='/userfs/godot/app_userdata/Zend Garden/garden_v1.json';
(async()=>{
 const browser=await chromium.launch({headless:true,channel:'chrome'});
 try {
  const context=await browser.newContext({viewport:{width:1280,height:800},acceptDownloads:true});
  const errors=[],metrics=[];
  const latestVersion=Number((await fs.readFile('scripts/player_updates.gd','utf8')).match(/"version":(\d+)/)[1]);
  await context.route('**/*',async route=>{
   const url=new URL(route.request().url());
   if(url.origin!==HOME) {await route.abort();return;}
   if(url.pathname==='/api/session') {const packet=route.request().postDataJSON();metrics.push(packet);await route.fulfill({json:packet.action==='start'?{token:'fixture'}:{ok:true}});return;}
   if(url.pathname==='/fixture') {await route.fulfill({body:'<!doctype html><body>Fixture</body>',contentType:'text/html'});return;}
   const filename=path.join('build/web',url.pathname==='/'?'index.html':url.pathname);
   if(!path.resolve(filename).startsWith(path.resolve('build/web')+path.sep)) {await route.abort();return;}
   try {
    const body=await fs.readFile(filename),ext=path.extname(filename);
    const contentType={'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm','.json':'application/json','.css':'text/css','.png':'image/png','.webp':'image/webp'}[ext] || 'application/octet-stream';
    const headers=url.pathname==='/'?{'Content-Security-Policy':"default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self'; worker-src 'self' blob:; media-src 'self' blob:"}:{};
    await route.fulfill({body,contentType,headers});
   } catch {await route.fulfill({status:404,body:'Missing fixture asset'});}
  });
  const page=await context.newPage();page.on('pageerror',error=>errors.push(error.message));
  page.on('console',message=>{console.log('BROWSER:',message.text());if(/SCRIPT ERROR|ERROR:|EvalError/.test(message.text()))errors.push(message.text());});
  await page.goto(HOME+'/fixture');
  const original={version:2,day:17,coins:240,clock:.3,plants:[{id:147,plot:0,pos:[1,-2],age:3,water:2,stress:0,shape_seed:41}],objects:[],names:['Miso','Clover'],
   settings:{intro_seen:true,updates_seen:latestVersion,controls:'keyboard',graphics:'mobile',music_volume:0,request_notifications:false},inventory:{'147':4},
   owned_surfaces:['soil','sand'],bed_surfaces:{'0':'sand'}};
  await page.evaluate(async({original,SAVE})=>{
   await new Promise((resolve,reject)=>{
    const req=indexedDB.open('/userfs',21);req.onupgradeneeded=()=>{const store=req.result.createObjectStore('FILE_DATA');store.createIndex('timestamp','timestamp');};
    req.onsuccess=()=>{
     const db=req.result,tx=db.transaction('FILE_DATA','readwrite'),store=tx.objectStore('FILE_DATA'),timestamp=new Date();
     for(const dir of ['/userfs/godot','/userfs/godot/app_userdata','/userfs/godot/app_userdata/Zend Garden'])store.put({mode:0o40755,timestamp},dir);
     store.put({mode:0o100666,timestamp,contents:new TextEncoder().encode(JSON.stringify(original))},SAVE);
     tx.oncomplete=()=>{db.close();resolve();};tx.onabort=()=>reject(tx.error);
    };
   });
  },{original,SAVE});
  const enter=async()=>{
   await page.getByRole('button',{name:'Enter the garden',exact:true}).click();
   await page.locator('#welcome').waitFor({state:'hidden',timeout:180000});
   // Loading can outlast transient activation; a real click resumes mouse look.
   await page.mouse.click(640,400);
   // Software WebGL can advance the simulation much more slowly than wall time.
   await page.waitForFunction(()=>window.analyticsAdvanced>0,{},{timeout:90000});
   await page.evaluate(()=>window.ZendTelemetry.report());
   assert.equal(metrics.find(packet=>packet.action==='start').version,latestVersion,'Godot must configure the session version under strict CSP');
   assert(metrics.filter(packet=>packet.action==='report').at(-1).advancing>0,'Real Godot clock time must reach the browser');
   await page.keyboard.press('Escape');
   await page.waitForTimeout(1000);
   await page.screenshot({path:path.resolve('captures/analytics-game-paused.png')});
   console.log('Browser garden entered; pointer lock:',await page.evaluate(()=>document.pointerLockElement?.id || 'released'));
   assert.equal(await page.evaluate(()=>document.pointerLockElement),null,'Settings must release mouse look');
  };
  await page.goto(HOME+'/');
  await page.waitForFunction(()=>window.ZendTelemetry);
  await page.evaluate(()=>{const advance=window.ZendTelemetry.advance;window.ZendTelemetry.advance=seconds=>{window.analyticsAdvanced=(window.analyticsAdvanced||0)+seconds;advance(seconds);};});
  await enter();
  const advancing=metrics.filter(packet=>packet.action==='report').at(-1).advancing;
  await page.waitForTimeout(5500);
  await page.evaluate(()=>window.ZendTelemetry.report());
  const paused=metrics.filter(packet=>packet.action==='report').at(-1);
  assert.equal(paused.advancing,advancing,'The garden clock must stay paused in menus');
  assert(paused.running>advancing,'Elapsed open time must include menu time');
  const stored=await page.evaluate(async()=>JSON.parse(new TextDecoder().decode(await (await import('/save-storage.js')).readCurrent())));
  assert.equal(stored.day,17);assert.equal(stored.coins,240);assert.equal(stored.plants[0].id,147);
  assert.equal(stored.bed_surfaces['0'],'sand');
  assert.deepEqual(errors,[]);
  console.log('ANALYTICS_GAME_RESULT: PASS — real Godot web version and advancing-time bridge, open time through menus, existing saved-garden mount and strict CSP');
  await context.close();
 } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
