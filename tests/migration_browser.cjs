// Isolated browser profiles and fixture saves only. Never touches a player's data.
// PLAYWRIGHT_MODULE can point at an existing Playwright installation.
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const {chromium,webkit} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const OLD='https://zend.tammas.com', HOME='https://zend.garden';
const SAVE='/userfs/godot/app_userdata/Zend Garden/garden_v1.json';
const sample=(day=17)=>({version:2,day,coins:240,clock:.3,plants:[{id:1,plot:0,pos:[1,-2],age:.7,water:2,stress:0}],
  objects:[],names:['Miso','Clover'],settings:{intro_seen:true,music_volume:0},inventory:{'1':4}});
const encode=data=>[...Buffer.from(JSON.stringify(data))];
const stub=`window.gameStarts=0; class Engine {
 static getMissingFeatures(){return [];} async init(){} async preloadFile(){}
 async start(config){window.gameStarts++; window.startArgs=config.args; window.ZendSaveGuard.ready();}
}`;

(async()=>{
 const relay=await import('../functions/api/garden-transfer/[action].js');
 const middleware=await import('../functions/_middleware.js');
 const sourceHTML=(await fs.readFile('web/shell.html','utf8')).replace('$GODOT_HEAD_INCLUDE','')
  .replace('$GODOT_URL','index.js').replace(/<script>window.ZEND_GODOT_CONFIG = \$GODOT_CONFIG;<\/script>/,
   '<script src="godot-config.js"></script>');
 const captures=path.resolve('captures/migration'); await fs.mkdir(captures,{recursive:true});
 for(const [name,engine] of [['chromium',chromium],['webkit',webkit]]) {
  const browser=await engine.launch({headless:true,...(name==='chromium'?{channel:'chrome'}:{})});
  let contexts=[];
  async function fixture() {
   const context=await browser.newContext({viewport:{width:1100,height:800}}); contexts.push(context);
   const state={bucket:new Map(),enabled:'true',failCreate:false,failRead:false,requests:[],errors:[]};
   const env={ZEND_MIGRATION_ENABLED:'true',GARDEN_TRANSFERS:{
    put:async(key,value)=>{state.bucket.set(key,value);},
    get:async key=>state.bucket.has(key)?{json:async()=>JSON.parse(state.bucket.get(key))}:null,
    delete:async key=>{state.bucket.delete(key);},
   }};
   async function asset(url) {
    const pathname=new URL(url).pathname;
    if(pathname==='/fixture') return new Response('<!doctype html><body>Test garden storage</body>',{headers:{'Content-Type':'text/html'}});
    if(['/','/index.html','/shell.html'].includes(pathname)) return new Response(sourceHTML,{headers:{'Content-Type':'text/html'}});
    if(pathname==='/index.js') return new Response(stub,{headers:{'Content-Type':'text/javascript'}});
    if(pathname==='/godot-config.js') return new Response('window.ZEND_GODOT_CONFIG={};',{headers:{'Content-Type':'text/javascript'}});
    if(pathname==='/pack.json') return Response.json({size:4,chunks:[{url:'pack/000.bin',size:4,sha256:'7aa07b4f8f4836ba076944655a7ed0e6e71d380b7b1fde1d8d1fe84dc8c6ad83'}]});
    if(pathname==='/pack/000.bin') return new Response(Buffer.from('GDPC'));
    let file=path.join('web',pathname);
    if(pathname==='/moving') file=path.join('web','moving.html');
    if(pathname.startsWith('/art/')) file=path.join('build/web',pathname);
    if(!path.resolve(file).startsWith(path.resolve(pathname.startsWith('/art/')?'build/web':'web')+path.sep)) return new Response('',{status:404});
    try { return new Response(await fs.readFile(file),{headers:{'Content-Type':pathname.endsWith('.js')?'text/javascript':pathname.endsWith('.css')?'text/css':pathname==='/moving'||pathname.endsWith('.html')?'text/html':pathname.endsWith('.png')?'image/png':'image/jpeg'}}); }
    catch { return new Response('',{status:404}); }
   }
   await context.route('**/*',async route=>{
    const req=route.request(),url=new URL(req.url());
    if(![OLD,HOME].includes(url.origin)) {await route.abort();return;}
    state.requests.push(url.origin+url.pathname);
    const request=new Request(req.url(),{method:req.method(),headers:req.headers(),...(req.postData()?{body:req.postData()}:{} )});
    let response;
    env.ZEND_MIGRATION_ENABLED=state.enabled;
    if(url.pathname.startsWith('/api/garden-transfer/')) {
     const action=url.pathname.split('/').pop();
     if((action==='create' && state.failCreate)||(action==='read' && state.failRead))
      response=Response.json({}, {status:503,headers:{'Access-Control-Allow-Origin':req.headers().origin || HOME}});
     else response=await relay.onRequest({request,env,params:{action}});
    } else response=await middleware.onRequest({request,env:{...env,ASSETS:{fetch:r=>asset(r.url)}},next:()=>asset(req.url())});
    const headers=Object.fromEntries(response.headers);
    if(!headers['content-security-policy'] && !url.pathname.startsWith('/api/'))
     headers['content-security-policy']="default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self'; object-src 'none'; frame-ancestors 'none'";
    await route.fulfill({status:response.status,headers,body:Buffer.from(await response.arrayBuffer())});
   });
   await context.addInitScript(()=>{
    window.sourceTransactions=[];
    const tx=IDBDatabase.prototype.transaction;
    IDBDatabase.prototype.transaction=function(store,mode,...rest){
     if(location.origin==='https://zend.tammas.com') window.sourceTransactions.push([this.name,mode || 'readonly']);
     return tx.call(this,store,mode,...rest);
    };
    const put=IDBObjectStore.prototype.put;
    IDBObjectStore.prototype.put=function(value,key){
     if(location.origin==='https://zend.garden') {
      if(localStorage.getItem('fail-save')==='1' && this.transaction.db.name==='/userfs' && key.endsWith('/garden_v1.json'))
       throw new DOMException('Injected full storage','QuotaExceededError');
      if(localStorage.getItem('fail-receipt')==='1' && this.transaction.db.name==='zend-garden-migration-v1' && key.startsWith('completed:'))
       throw new DOMException('Injected tab-close checkpoint','QuotaExceededError');
     }
     return put.call(this,value,key);
    };
   });
   const page=await context.newPage();page.on('pageerror',error=>state.errors.push(error.message));
   return {context,page,state};
  }
  async function seed(page,origin,bytes,extra=false) {
   await page.goto(origin+'/fixture');
   await page.evaluate(async({bytes,SAVE,extra})=>{
    await new Promise((resolve,reject)=>{
     const req=indexedDB.open('/userfs',21);
     req.onupgradeneeded=()=>{const store=req.result.createObjectStore('FILE_DATA');store.createIndex('timestamp','timestamp');};
     req.onerror=()=>reject(req.error);req.onsuccess=()=>{
      const db=req.result,tx=db.transaction('FILE_DATA','readwrite'),store=tx.objectStore('FILE_DATA');
      store.put({mode:0o100666,timestamp:new Date(1700000000000),contents:new Uint8Array(bytes)},SAVE);
      store.put({mode:0o100666,timestamp:new Date(1700000000000),contents:new Uint8Array([1,2,3])},'/userfs/untouched-file');
      if(extra) store.put({mode:0o100666,timestamp:new Date(1700000000000),contents:new Uint8Array(bytes)},'/userfs/legacy/garden_v1.json');
      tx.oncomplete=()=>{db.close();resolve();};tx.onabort=()=>reject(tx.error);
     };
    });
   },{bytes,SAVE,extra});
  }
  async function snapshot(page) {
   return page.evaluate(async()=>{
    const req=indexedDB.open('/userfs');
    return new Promise((resolve,reject)=>{
     req.onupgradeneeded=()=>req.transaction.abort();
     req.onerror=()=>reject(req.error);req.onsuccess=()=>{
      const db=req.result,tx=db.transaction('FILE_DATA','readonly'),store=tx.objectStore('FILE_DATA');
      const result=[];store.openCursor().onsuccess=e=>{const c=e.target.result;if(c){result.push([c.key,c.value.mode,c.value.timestamp.getTime(),Array.from(c.value.contents || [])]);c.continue();}};
      tx.oncomplete=()=>{db.close();resolve(result);};tx.onabort=()=>reject(tx.error);
     };
    });
   });
  }
  async function current(page){return page.evaluate(async()=>{const m=await import('/migration-storage.js');const b=await m.readCurrent();return b ? [...b]:null;});}
  async function sourceUntouched(f,before) {
   const p=await f.context.newPage();await p.goto(OLD+'/fixture');assert.deepEqual(await snapshot(p),before);await p.close();
  }
  async function move(page,automatic=false) {
   await page.goto(OLD+'/');
   await page.getByRole('button',{name:'Go to zend.garden',exact:true}).waitFor();
   assert.equal(await page.locator('script[src$="index.js"]').count(),0,'Moving page must not load Godot');
   assert((await page.evaluate(()=>window.sourceTransactions)).every(([db,mode])=>db==='/userfs' && mode==='readonly'));
   if(!automatic) await page.getByRole('button',{name:'Go to zend.garden',exact:true}).click();
   await page.waitForURL(HOME+'/**');
  }
  async function finish(page) {
   await page.getByRole('button',{name:'Continue to the garden',exact:true}).click();
   await page.waitForFunction(()=>document.getElementById('welcome').hidden || !document.getElementById('play').disabled);
  }
  try {
   // Success, original bytes retained, immutable backup, auto redirect, no repeated overwrite.
   let f=await fixture(); const original=encode(sample());await seed(f.page,OLD,original);const before=await snapshot(f.page);
   await f.page.goto(OLD+'/');await f.page.getByRole('button',{name:'Go to zend.garden',exact:true}).waitFor();
   await f.page.screenshot({path:path.join(captures,`${name}-moving-desktop.png`)});
   await f.page.setViewportSize({width:390,height:844});
   await f.page.screenshot({path:path.join(captures,`${name}-moving-phone.png`)});
   await f.page.waitForURL(HOME+'/**');await finish(f.page);
   assert.deepEqual(await current(f.page),original);assert.equal(f.state.bucket.size,0);
   await sourceUntouched(f,before);
   const newer=encode(sample(31));await seed(f.page,HOME,newer);
   await move(f.page);await f.page.waitForFunction(()=>document.getElementById('status').textContent.includes('already home'));
   assert.deepEqual(await current(f.page),newer,'Revisiting old site must not replace new progress');
   assert.equal(new URL(f.page.url()).hash,'');assert.equal(f.state.bucket.size,0);assert.deepEqual(f.state.errors,[]);
   // A different existing garden requires a choice; both copies survive.
   for(const keep of [true,false]) {
    f=await fixture();await seed(f.page,OLD,original);const oldBefore=await snapshot(f.page);
    await seed(f.page,HOME,newer);await move(f.page);
    await f.page.getByRole('heading',{name:'Two little gardens'}).waitFor();
    assert(await f.page.locator('#play').isDisabled());assert.deepEqual(await current(f.page),newer);
    await f.page.screenshot({path:path.join(captures,`${name}-choose-${keep}.png`)});
    await f.page.getByRole('button',{name:keep?'Keep the garden here':'Bring my original garden',exact:true}).click();await finish(f.page);
    assert.deepEqual(await current(f.page),keep?newer:original);
    const archives=await f.page.evaluate(()=>new Promise(resolve=>{
     const req=indexedDB.open('zend-garden-migration-v1');req.onsuccess=()=>{
      const db=req.result,tx=db.transaction('copies','readonly'),store=tx.objectStore('copies');
      store.getAllKeys().onsuccess=e=>resolve(e.target.result);tx.oncomplete=()=>db.close();
     };
    }));
    assert(archives.some(key=>key.startsWith('original:')));
    if(!keep) assert(archives.some(key=>key.startsWith('before:')));
    const storedOriginal=await f.page.evaluate(()=>new Promise(resolve=>{
     const req=indexedDB.open('zend-garden-migration-v1');req.onsuccess=()=>{
      const db=req.result,tx=db.transaction('copies','readonly'),store=tx.objectStore('copies');
      store.openCursor().onsuccess=e=>{const c=e.target.result;if(c){if(c.key.startsWith('original:')) resolve([...c.value.bytes]);else c.continue();}};
      tx.oncomplete=()=>db.close();
     };
    }));
    assert.deepEqual(storedOriginal,original);
    await sourceUntouched(f,oldBefore);assert.deepEqual(f.state.errors,[]);
   }
   // Source/relay errors never start the game or alter the old database.
   for(const failure of ['create','read','invalid']) {
    f=await fixture();const bytes=failure==='invalid'?[1,2,3]:original;
    await seed(f.page,OLD,bytes);const oldBefore=await snapshot(f.page);
    f.state.failCreate=failure==='create';f.state.failRead=failure==='read';
    if(failure==='read') await move(f.page);else await f.page.goto(OLD+'/');
    await f.page.getByRole('heading',{name:'Your garden can wait a moment'}).waitFor();
    assert.equal(await f.page.evaluate(()=>window.gameStarts || 0),0);
    await sourceUntouched(f,oldBefore);assert.deepEqual(f.state.errors,[]);
   }
   // Failed promotion rolls back the transaction; pending copy resumes without the relay.
   for(const checkpoint of ['fail-save','fail-save-existing','fail-receipt']) {
    f=await fixture();await seed(f.page,OLD,original);const oldBefore=await snapshot(f.page);
    if(checkpoint==='fail-save-existing') await seed(f.page,HOME,newer);else await f.page.goto(HOME+'/fixture');
    const flag=checkpoint==='fail-save-existing'?'fail-save':checkpoint;
    await f.page.evaluate(key=>localStorage.setItem(key,'1'),flag);
    await move(f.page);
    if(checkpoint==='fail-save-existing') await f.page.getByRole('button',{name:'Bring my original garden',exact:true}).click();
    await f.page.getByRole('heading',{name:'Your garden can wait a moment'}).waitFor();
    assert.deepEqual(await current(f.page),checkpoint==='fail-save'?null:checkpoint==='fail-save-existing'?newer:original);
    await sourceUntouched(f,oldBefore);
    f.state.failRead=true; // deliberately make recovery independent of the server
    await f.page.evaluate(key=>localStorage.removeItem(key),flag);await f.page.reload();
    if(checkpoint==='fail-save-existing') await f.page.getByRole('button',{name:'Bring my original garden',exact:true}).click();
    await finish(f.page);
    assert.deepEqual(await current(f.page),original);assert.deepEqual(f.state.errors,[]);
   }
   // An open game tab blocks import; an explicit retry after closure can continue.
   f=await fixture();await seed(f.page,OLD,original);
   const other=await f.context.newPage();await other.goto(HOME+'/fixture');
   await other.evaluate(async()=>{const m=await import('/migration-storage.js');window.releaseGarden=await m.holdGardenSession();});
   await move(f.page);await f.page.getByRole('heading',{name:'Your garden can wait a moment'}).waitFor();
   assert.equal(await current(f.page),null);await other.close();await f.page.reload();await finish(f.page);
   assert.deepEqual(await current(f.page),original);
   // A missing destination after completion needs an explicit recovery choice.
   f=await fixture();await seed(f.page,OLD,original);await move(f.page);await finish(f.page);
   await f.page.evaluate(SAVE=>new Promise(resolve=>{
    const req=indexedDB.open('/userfs');req.onsuccess=()=>{
     const db=req.result,tx=db.transaction('FILE_DATA','readwrite');tx.objectStore('FILE_DATA').delete(SAVE);
     tx.oncomplete=()=>{db.close();resolve();};
    };
   }),SAVE);
   await move(f.page);await f.page.getByRole('heading',{name:'Bring your garden home again'}).waitFor();
   assert.equal(await current(f.page),null);
   await f.page.getByRole('button',{name:'Bring my original garden',exact:true}).click();await finish(f.page);
   assert.deepEqual(await current(f.page),original);
   // No-save visitor does not leave a newly-created source database behind.
   f=await fixture();await move(f.page);await f.page.waitForFunction(()=>!document.getElementById('play').disabled);
   const p=await f.context.newPage();await p.goto(OLD+'/fixture');
   assert(!(await p.evaluate(()=>indexedDB.databases())).some(db=>db.name==='/userfs'));
   // Disabled rollout and stay link serve the game; never initiate transfer.
   f=await fixture();f.state.enabled='false';await f.page.goto(OLD+'/');
   await f.page.waitForFunction(()=>!document.getElementById('play').disabled);assert.equal(await f.page.locator('#migration').count(),0);
   f.state.enabled='true';await f.page.goto(OLD+'/?stay=1');
   await f.page.waitForFunction(()=>!document.getElementById('play').disabled);assert.equal(await f.page.locator('#migration').count(),0);
   assert(!f.state.requests.some(url=>url.endsWith('/create')));
   console.log(`MIGRATION_BROWSER_RESULT ${name}: PASS — real IndexedDB, unchanged source, automatic move, conflicts, preserved copies, retries, quota/checkpoint failures, tab lock, empty browser and rollback`);
  } finally {for(const context of contexts) await context.close();await browser.close();}
 }
})().catch(error=>{console.error(error);process.exitCode=1;});
