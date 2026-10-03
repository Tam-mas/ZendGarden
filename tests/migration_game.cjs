// Verify the actual exported Godot runtime, including a failed IndexedDB mount.
const assert=require('node:assert/strict');
const fs=require('node:fs/promises');
const path=require('node:path');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const HOME='https://zend.garden',SAVE='/userfs/godot/app_userdata/Zend Garden/garden_v1.json';
(async()=>{
 const browser=await chromium.launch({headless:true,channel:'chrome'});
 try {
  const cases=process.env.ZEND_WELCOME_ONLY?[[2,false,true]]:[[1,false],[2,false],[2,true],[2,false,true]];
  for(const [version,brokenMount,activeTutorial] of cases) {
   const context=await browser.newContext({viewport:{width:800,height:600}});
   const errors=[];
   await context.route('**/*',async route=>{
    const url=new URL(route.request().url());
    if(url.origin!==HOME) {await route.abort();return;}
    if(url.pathname==='/fixture') {await route.fulfill({body:'<!doctype html><body>Fixture</body>',contentType:'text/html'});return;}
    let filename=path.join('build/web',url.pathname==='/'?'index.html':url.pathname);
    if(!path.resolve(filename).startsWith(path.resolve('build/web')+path.sep)) {await route.abort();return;}
    try {
     let body=await fs.readFile(filename);
     if(brokenMount && url.pathname==='/index.js') {
      const source=body.toString();assert(source.includes("module['initFS'](paths)"));
      body=Buffer.from(source.replace("module['initFS'](paths)","module['initFS']([])"));
     }
     const ext=path.extname(filename),type={'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm','.json':'application/json','.css':'text/css','.png':'image/png','.jpg':'image/jpeg'}[ext] || 'application/octet-stream';
     const headers=url.pathname==='/'?{'Content-Security-Policy':"default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self'; worker-src 'self' blob:; media-src 'self' blob:"}:{};
     await route.fulfill({body,contentType:type,headers});
    } catch(error) {await route.fulfill({status:404,body:'Missing fixture asset'});}
   });
   const page=await context.newPage();page.on('pageerror',e=>errors.push(e.message));
   page.on('console',message=>{if(message.text().includes('SCRIPT ERROR') || message.text().includes('ERROR:')) errors.push(message.text());});
   await page.goto(HOME+'/fixture');
   const original=JSON.stringify({version,day:17,coins:240,clock:.3,
    plants:[{id:1,plot:0,pos:[1,-2],age:.7,water:2,stress:0,shape_seed:41}],objects:[],names:['Miso','Clover'],
    settings:{intro_seen:true,graphics:'mobile',music_volume:0},inventory:{'1':4},
    ...(activeTutorial?{tutorial:{active:true,step:2,pos:[1,-2],plant:1,seed:41,morning:17}}:{})});
   await page.evaluate(async({original,SAVE})=>{
    await new Promise((resolve,reject)=>{
     const req=indexedDB.open('/userfs',21);req.onupgradeneeded=()=>{const store=req.result.createObjectStore('FILE_DATA');store.createIndex('timestamp','timestamp');};
     req.onsuccess=()=>{
      const db=req.result,tx=db.transaction('FILE_DATA','readwrite'),store=tx.objectStore('FILE_DATA'),timestamp=new Date();
      for(const dir of ['/userfs/godot','/userfs/godot/app_userdata','/userfs/godot/app_userdata/Zend Garden']) store.put({mode:0o40755,timestamp},dir);
      store.put({mode:0o100666,timestamp,contents:new TextEncoder().encode(original)},SAVE);
      tx.oncomplete=()=>{db.close();resolve();};tx.onabort=()=>reject(tx.error);
     };
    });
   },{original,SAVE});
   await page.goto(HOME+'/');await page.getByRole('button',{name:'Enter the garden',exact:true}).click();
   if(brokenMount) {
    await page.waitForFunction(()=>document.getElementById('status').textContent.includes('could not be opened safely'),{},{timeout:180000});
    assert(await page.locator('#welcome').isVisible());
    const bytes=await page.evaluate(async()=>{const m=await import('/migration-storage.js');return new TextDecoder().decode(await m.readCurrent());});
    assert.equal(bytes,original,'Failed mount must never overwrite the persisted save');
    console.log('MIGRATION_GAME_RESULT failed mount: PASS — actual Godot halted before world/autosave and retained the saved bytes');
   } else {
    await page.locator('#welcome').waitFor({state:'hidden',timeout:180000});
    await page.screenshot({path:path.resolve('captures/migration/arrived-in-game.png')});
    if(activeTutorial) {
     await page.locator('#canvas').focus();
     await page.keyboard.press('Enter');
     await page.waitForFunction(async()=>{
      const m=await import('/migration-storage.js');const bytes=await m.readCurrent();
      if(!bytes)return false;
      const save=JSON.parse(new TextDecoder().decode(bytes));
      return save.tutorial?.step===3 && save.day===18 && save.clock>.29 && save.clock<.31;
     },{},{timeout:45000});
     const save=await page.evaluate(async()=>{
      const m=await import('/migration-storage.js');return JSON.parse(new TextDecoder().decode(await m.readCurrent()));
     });
     assert.equal(save.version,2);assert.equal(save.coins,240);assert.equal(save.inventory['1'],4);
     assert.equal(save.tutorial.active,true);
     // Leave the animated morning enough time to be presented in software WebGL.
     await page.waitForTimeout(14000);
     await page.screenshot({path:path.resolve('captures/migration/welcome-resumed.png')});
     console.log('MIGRATION_GAME_RESULT resumed welcome: PASS — real keyboard input advanced the saved lesson and persisted a new morning');
    } else console.log(`MIGRATION_GAME_RESULT imported v${version} garden: PASS — actual Godot mounted and opened the verified fixture save`);
   }
   assert.deepEqual(errors,[]);await context.close();
  }
 } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
