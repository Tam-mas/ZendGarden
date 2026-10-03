// Opt-in production smoke check. Uses disposable browser profiles and fixture saves.
// Never opens a player's profile or clears real site data.
const assert=require('node:assert/strict');
const path=require('node:path');
const fs=require('node:fs/promises');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const OLD='https://zend.tammas.com',HOME='https://zend.garden';
const SAVE='/userfs/godot/app_userdata/Zend Garden/garden_v1.json';
const fixture=JSON.stringify({version:2,day:17,coins:240,clock:.3,
 plants:[{id:1,plot:0,pos:[1,-2],age:.7,water:2,stress:0}],objects:[],names:['Miso','Clover'],
 settings:{intro_seen:true,graphics:'mobile',music_volume:0},inventory:{'1':4},
 watered_ground:{'2:-4':{x:1,z:-2,radius:.65,until:18.3}}});
const deadline=setTimeout(()=>{console.error('Live check exceeded its six-minute deadline');process.exit(1);},360000);
deadline.unref();

(async()=>{
 assert.equal(process.env.ZEND_LIVE_CHECK,'1','Set ZEND_LIVE_CHECK=1 explicitly to run this network check');
 const disabled=process.argv.includes('--disabled');
 const origin=process.env.ZEND_CHECK_ORIGIN || HOME;
 const browser=await chromium.launch({headless:true,channel:'chrome'});
 const context=await browser.newContext({viewport:{width:1000,height:760}});
 const page=await context.newPage(),errors=[];
 console.log('MIGRATION_LIVE_PROGRESS disposable browser ready');
 const progress=setInterval(()=>page.locator('#status').textContent({timeout:3000}).then(text=>console.log('MIGRATION_LIVE_PROGRESS',text)).catch(()=>{}),30000);
 page.on('pageerror',e=>errors.push(e.message));
 page.on('console',m=>{if(m.text().includes('SCRIPT ERROR')) errors.push(m.text());});
 page.on('response',r=>{if(new URL(r.url()).pathname.startsWith('/api/garden-transfer/')) console.log('MIGRATION_LIVE_API',new URL(r.url()).pathname,r.status(),r.headers()['access-control-allow-origin'] || '');});
 page.on('requestfailed',r=>console.log('MIGRATION_LIVE_NETWORK',new URL(r.url()).pathname,r.failure()?.errorText));
 const captures=path.resolve('captures/migration');await fs.mkdir(captures,{recursive:true});
 try {
  const status=await context.request.get(origin+'/api/garden-transfer/status');
  assert.equal(status.status(),200);assert.equal((await status.json()).enabled,!disabled);
  if(disabled) {
   await page.goto(origin+'/');
   await page.getByRole('button',{name:'Enter the garden',exact:true}).click();
   await page.locator('#welcome').waitFor({state:'hidden',timeout:240000});
   await page.screenshot({path:path.join(captures,'live-disabled-game.png')});
   assert.deepEqual(errors,[]);
   console.log('MIGRATION_LIVE_RESULT disabled deployment: PASS — actual game starts; transfer API is off');
   return;
  }
  // Only the seed page is intercepted; all migration/assets/API requests use production.
  const seedURL=OLD+'/__disposable_migration_fixture';
  await page.route(seedURL,route=>route.fulfill({body:'<!doctype html><body>Disposable fixture</body>',contentType:'text/html'}));
  await page.goto(seedURL);
  await page.evaluate(async({fixture,SAVE})=>{
   await new Promise((resolve,reject)=>{
    const req=indexedDB.open('/userfs',21);
    req.onupgradeneeded=()=>{const s=req.result.createObjectStore('FILE_DATA');s.createIndex('timestamp','timestamp');};
    req.onerror=()=>reject(req.error);req.onsuccess=()=>{
     const db=req.result,tx=db.transaction('FILE_DATA','readwrite'),store=tx.objectStore('FILE_DATA'),timestamp=new Date();
     for(const dir of ['/userfs/godot','/userfs/godot/app_userdata','/userfs/godot/app_userdata/Zend Garden']) store.put({mode:0o40755,timestamp},dir);
     store.put({mode:0o100666,timestamp,contents:new TextEncoder().encode(fixture)},SAVE);
     tx.oncomplete=()=>{db.close();resolve();};tx.onabort=()=>reject(tx.error);
    };
   });
  },{fixture,SAVE});
  await page.unroute(seedURL);
  await context.addInitScript(()=>{
   window.oldTransactions=[];
   const transaction=IDBDatabase.prototype.transaction;
   IDBDatabase.prototype.transaction=function(store,mode,...args){
    if(location.origin==='https://zend.tammas.com') window.oldTransactions.push(mode || 'readonly');
    return transaction.call(this,store,mode,...args);
   };
  });
  await page.goto(OLD+'/',{waitUntil:'domcontentloaded'});
  await page.getByText('Your little garden is moving to its new cozy home at zend.garden.',{exact:true}).waitFor();
  await page.getByRole('button',{name:'Go to zend.garden',exact:true}).waitFor();
  assert((await page.evaluate(()=>window.oldTransactions)).every(mode=>mode==='readonly'));
  await page.screenshot({path:path.join(captures,'live-moving.png')});
  await page.waitForURL(url=>url.origin===HOME,{timeout:45000});
  await page.getByRole('button',{name:'Continue to the garden',exact:true}).waitFor({timeout:45000});
  assert.equal(await page.evaluate(async()=>new TextDecoder().decode(await (await import('/migration-storage.js')).readCurrent())),fixture);
  assert.equal(new URL(page.url()).hash,'');
  await page.screenshot({path:path.join(captures,'live-arrived.png')});
  await page.getByRole('button',{name:'Continue to the garden',exact:true}).click();
  await page.locator('#welcome').waitFor({state:'hidden',timeout:240000});
  await page.screenshot({path:path.join(captures,'live-arrived-game.png')});
  assert.deepEqual(errors,[]);
  console.log('MIGRATION_LIVE_RESULT transfer: PASS — production R2, automatic redirect, exact-byte import and Godot startup');
  await page.goto(HOME+'/');
  const latest=await page.evaluate(async()=>new TextDecoder().decode(await (await import('/migration-storage.js')).readCurrent()));
  const original=await page.evaluate(async()=>{
   const m=await import('/migration-storage.js');const copy=await m.completedMove();return copy;
  });
  assert(original,'Completion receipt exists');
  await page.getByRole('button',{name:'Enter the garden',exact:true}).click();
  await page.locator('#welcome').waitFor({state:'hidden',timeout:240000});
  assert.deepEqual(errors,[]);
  console.log('MIGRATION_LIVE_RESULT watered reload: PASS — migrated watered garden reopens in the actual production game');
  await page.goto(OLD+'/?stay=1');
  assert(await page.getByRole('button',{name:'Enter the garden',exact:true}).isVisible());
  assert.equal(await page.evaluate(async()=>new TextDecoder().decode(await (await import('/migration-storage.js')).readOriginal())),fixture);
  await page.goto(OLD+'/');
  await page.waitForURL(url=>url.origin===HOME,{timeout:45000});
  await page.getByText('Your garden is already home here. Your latest progress has been kept.',{exact:true}).waitFor({timeout:45000});
  assert.equal(await page.evaluate(async()=>new TextDecoder().decode(await (await import('/migration-storage.js')).readCurrent())),latest);
  assert.deepEqual(errors,[]);
  console.log('MIGRATION_LIVE_RESULT recovery/repeat: PASS — original unchanged, stay route available, latest new-domain save retained');
 } catch(error) {
  console.log('MIGRATION_LIVE_STATUS',await page.locator('#status').textContent().catch(()=>''),await page.locator('.move-message').textContent().catch(()=>''));
  await page.screenshot({path:path.join(captures,'live-failure.png')}).catch(()=>{});
  throw error;
 } finally {clearInterval(progress);clearTimeout(deadline);await context.close();await browser.close();}
})().catch(error=>{console.error(error.message);process.exitCode=1;});
