// Download/upload through the real Settings buttons in an isolated browser save.
const assert=require('node:assert/strict');
const fs=require('node:fs/promises');
const path=require('node:path');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const HOME='https://zend.garden',SAVE='/userfs/godot/app_userdata/Zend Garden/garden_v1.json';
(async()=>{
 const browser=await chromium.launch({headless:true,channel:'chrome'});
 try {
  const context=await browser.newContext({viewport:{width:1280,height:800},acceptDownloads:true});
  const errors=[];
  await context.route('**/*',async route=>{
   const url=new URL(route.request().url());
   if(url.origin!==HOME) {await route.abort();return;}
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
  page.on('console',message=>{console.log('BROWSER:',message.text());if(/SCRIPT ERROR|ERROR:/.test(message.text()))errors.push(message.text());});
  await page.goto(HOME+'/fixture');
  const original={version:2,day:17,coins:240,clock:.3,plants:[{id:147,plot:0,pos:[1,-2],age:3,water:2,stress:0,shape_seed:41}],objects:[],names:['Miso','Clover'],
   settings:{intro_seen:true,updates_seen:33,controls:'keyboard',graphics:'mobile',music_volume:0,request_notifications:false},inventory:{'147':4},
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
   await page.keyboard.press('Escape');
   await page.waitForTimeout(1000);
   await page.screenshot({path:path.resolve('captures/save-files-browser-settings.png')});
   console.log('Browser garden entered; pointer lock:',await page.evaluate(()=>document.pointerLockElement?.id || 'released'));
   assert.equal(await page.evaluate(()=>document.pointerLockElement),null,'Settings must release the pointer before a file action');
  };
  const download=async(y=326)=>{
   const event=page.waitForEvent('download');await page.mouse.click(160,y,{delay:150});
   await page.waitForTimeout(1500);
   await page.screenshot({path:path.resolve('captures/save-files-browser-after-download.png')});
   const file=await event;
   assert.match(file.suggestedFilename(),/\.json$/);
   return JSON.parse(await fs.readFile(await file.path(),'utf8'));
  };
  const choose=async(data,name='garden-copy.json')=>{
   const event=page.waitForEvent('filechooser');await page.mouse.click(160,372,{delay:150});
   await page.waitForTimeout(1000);
   console.log('Picker state:',await page.evaluate(()=>({lock:document.pointerLockElement?.id,input:!!document.querySelector('input[type=file]'),active:document.activeElement?.id})));
   await page.screenshot({path:path.resolve('captures/save-files-browser-picker.png')});
   await (await event).setFiles({name,mimeType:'application/json',buffer:Buffer.from(typeof data==='string'?data:JSON.stringify(data))});
   await page.waitForTimeout(1500);
  };
  await page.goto(HOME+'/');
  await page.evaluate(()=>{const choose=window.ZendSaveFiles.choose;window.ZendSaveFiles.choose=function(callback){console.log('File picker called, activation:',navigator.userActivation.isActive);return choose.call(this,callback);};});
  await enter();
  const exported=await download();console.log('Current garden downloaded.');
  assert.equal(exported.day,17);assert.equal(exported.coins,240);assert.equal(exported.plants[0].id,147);
  assert.equal(exported.bed_surfaces['0'],'sand');
  await choose('{broken');
  assert.equal((await download()).day,17,'Invalid upload must leave live garden unchanged');
  const incoming={...original,day:29,coins:419,bed_surfaces:{'0':'gravel'},owned_surfaces:['soil','gravel']};
  await choose(incoming);
  await page.keyboard.press('Escape');await page.waitForTimeout(500);
  assert.equal((await download()).coins,240,'Cancelling preview must retain garden');
  await choose(incoming);
  console.log('Confirmation preview ready.');
  await page.screenshot({path:path.resolve('captures/save-upload-browser-confirmation.png')});
  // The centered 420px confirmation at this desktop viewport has its final
  // action here. Native tests separately verify phone and landscape fitting.
  await page.mouse.click(640,525,{delay:150});
  const waitForImported=async()=>{
   const deadline=Date.now()+45000;
   while(Date.now()<deadline) {
    const day=await page.evaluate(async()=>{
     const storage=await import('/migration-storage.js');const bytes=await storage.readCurrent();
     return bytes ? JSON.parse(new TextDecoder().decode(bytes)).day : null;
    });
    if(day===29)return;
    await page.waitForTimeout(500);
   }
   throw new Error('Imported garden was not persisted within 45 seconds');
  };
  await waitForImported();
  await page.waitForTimeout(1000);
  await page.keyboard.press('Escape');await page.waitForTimeout(700);
  const restored=await download();
  assert.equal(restored.day,29);assert.equal(restored.coins,419);assert.equal(restored.bed_surfaces['0'],'gravel');
  const backup=await download(418);assert.equal(backup.day,17);assert.equal(backup.coins,240);assert.equal(backup.bed_surfaces['0'],'sand');
  await page.reload();await enter();
  const persisted=await download();assert.equal(persisted.day,29);assert.equal(persisted.coins,419);
  assert.deepEqual(errors,[]);
  console.log('SAVE_FILES_GAME_RESULT: PASS — actual Settings download, invalid/cancelled upload, confirmed import, previous-garden download and persistence after page reload');
  await context.close();
 } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
