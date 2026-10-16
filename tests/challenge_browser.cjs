// Real browser mode switching against a local export and isolated IndexedDB.
const assert=require('node:assert/strict');
const fs=require('node:fs/promises');
const path=require('node:path');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
let HOME;
const DIR='/userfs/godot/app_userdata/Zend Garden';
(async()=>{
 // Worklet module fetches bypass Playwright routing; serve the same local
 // export on loopback so those requests remain local and resolve correctly.
 const server=require('node:http').createServer(async(req,res)=>{
  const url=new URL(req.url,'http://127.0.0.1');
  const filename=path.resolve('build/web','.'+(url.pathname==='/'?'/index.html':url.pathname));
  if(!filename.startsWith(path.resolve('build/web')+path.sep)){res.writeHead(403);res.end();return;}
  try {
   const body=await fs.readFile(filename);
   res.setHeader('Content-Type',({'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm','.json':'application/json'})[path.extname(filename)]||'application/octet-stream');
   res.end(body);
  } catch {res.writeHead(404);res.end();}
 });
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 HOME='http://127.0.0.1:'+server.address().port;
 const browser=await chromium.launch({headless:true,channel:'chrome'});
 try {
  const context=await browser.newContext({viewport:{width:1440,height:900}});
  const errors=[];
  const version=Number((await fs.readFile('scripts/player_updates.gd','utf8')).match(/"version":(\d+)/)[1]);
  await context.route('**/*',async route=>{
   const url=new URL(route.request().url());
   if(url.origin!==HOME) {await route.abort();return;}
   if(url.pathname==='/fixture') {await route.fulfill({body:'<!doctype html><body>Fixture</body>',contentType:'text/html'});return;}
   if(url.pathname==='/api/session') return route.fulfill({json:route.request().postDataJSON().action==='start'?{token:'fixture'}:{ok:true}});
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
  const settings={intro_seen:true,updates_seen:version,controls:'keyboard',graphics:'mobile',music_volume:0,request_notifications:false,reduced_motion:true};
  const free={version:3,day:17,coins:240,clock:.3,plants:[{id:0,plot:0,pos:[1,1],age:1,water:0,stress:0}],objects:[],settings};
  const challenge={version:4,garden_mode:'challenge',day:5,coins:222,clock:.3,settings,unlocked_plants:[0,2,48],
   plants:[{id:0,plot:0,pos:[1,1],age:2,water:1,stress:0,dry_days:0}],objects:[],
   challenge:{rules:1,seed:829731,patches:{'0:0:0':{plot:0,weed:2,weed_age:3,mulch_until:0,clear_until:0,last_spawn:4}},trimmings:0,season:-1,offers:[],request:{},completed:[],intro:1,starter_claimed:false,report:'Fixture garden'}};
  await page.evaluate(async({free,challenge,DIR})=>{
   await new Promise((resolve,reject)=>{
    const req=indexedDB.open('/userfs',21);
    req.onupgradeneeded=()=>{const store=req.result.createObjectStore('FILE_DATA');store.createIndex('timestamp','timestamp');};
    req.onsuccess=()=>{
     const db=req.result,tx=db.transaction('FILE_DATA','readwrite'),store=tx.objectStore('FILE_DATA'),timestamp=new Date();
     for(const dir of ['/userfs/godot','/userfs/godot/app_userdata',DIR])store.put({mode:0o40755,timestamp},dir);
     for(const [name,data] of [['garden_v1.json',free],['challenge-garden.json',challenge],['garden-slots.json',{last:'challenge'}]])store.put({mode:0o100666,timestamp,contents:new TextEncoder().encode(JSON.stringify(data))},DIR+'/'+name);
     tx.oncomplete=()=>{db.close();resolve();};tx.onabort=()=>reject(tx.error);
    };
   });
  },{free,challenge,DIR});
  const read=async name=>page.evaluate(async({DIR,name})=>new Promise((resolve,reject)=>{
   const req=indexedDB.open('/userfs',21);req.onsuccess=()=>{
    const db=req.result,tx=db.transaction('FILE_DATA','readonly'),get=tx.objectStore('FILE_DATA').get(DIR+'/'+name);
    get.onsuccess=()=>resolve(get.result?.contents ? JSON.parse(new TextDecoder().decode(get.result.contents)):null);
    get.onerror=()=>reject(get.error);tx.oncomplete=()=>db.close();
   };
  }),{DIR,name});
  const waitMode=async mode=>{
   const deadline=Date.now()+60000;
   while(Date.now()<deadline){if((await read('garden-slots.json'))?.last===mode)return;await page.waitForTimeout(500);}
   throw new Error('Mode selection did not persist: '+mode);
  };
  await page.goto(HOME+'/');
  await page.getByRole('button',{name:'Enter the garden',exact:true}).click();
  await page.locator('#welcome').waitFor({state:'hidden',timeout:180000});
  await page.waitForTimeout(2000);
  await page.keyboard.press('k');await page.waitForTimeout(700);
  await page.screenshot({path:'captures/challenge/browser-care.png'});
  assert.equal(await page.evaluate(()=>document.pointerLockElement),null,'Care releases pointer');
  await page.keyboard.press('Escape');await page.waitForTimeout(700);
  await page.mouse.click(170,217);await page.waitForTimeout(700);
  await page.screenshot({path:'captures/challenge/browser-gardens.png'});
  await page.mouse.click(170,361);await waitMode('free');
  await page.waitForTimeout(3000);
  const savedChallenge=await read('challenge-garden.json');
  assert.equal(savedChallenge.version,4);assert.equal(savedChallenge.garden_mode,'challenge');assert.equal(savedChallenge.coins,222);
  await page.keyboard.press('g');await page.waitForTimeout(700);
  await page.keyboard.press('Escape');await page.waitForTimeout(700);
  await page.mouse.click(170,217);await page.waitForTimeout(700);
  await page.mouse.click(170,513);await waitMode('challenge');
  await page.waitForTimeout(3000);
  const savedFree=await read('garden_v1.json');assert.equal(savedFree.version,3);assert.equal(savedFree.coins,240);assert.equal(savedFree.day,18);assert.ok(savedFree.plants[0].age>1,'Free dry plants retain their gentle growth');
  await page.keyboard.press('k');await page.waitForTimeout(700);
  await page.screenshot({path:'captures/challenge/browser-returned.png'});
  assert.deepEqual(errors,[]);
  console.log('CHALLENGE_BROWSER_RESULT: PASS — actual mode buttons, separate saves, legacy Free growth format, Challenge care and persisted round trip');
  await context.close();
 } finally {await browser.close();await new Promise(resolve=>server.close(resolve));}
})().catch(error=>{console.error(error);process.exitCode=1;});
