// Relay contract and encryption tests, using only Node's standard library.
const assert = require('node:assert/strict');
const {webcrypto} = require('node:crypto');
global.crypto = webcrypto;
global.document = {body:{dataset:{}}};
(async () => {
  const {onRequest} = await import('../functions/api/garden-transfer/[action].js');
  const middleware = await import('../functions/_middleware.js');
  const format = await import('../web/save-format.js');
  const {sealCopy, unsealCopy} = await import('../web/migration.js');
  const originals = [1,2].map(version => new TextEncoder().encode(JSON.stringify({version, day:17,
    plants:[{id:0,plot:0,pos:[1.2,-2],age:.8,water:2,stress:0}], objects:[],
    settings:{intro_seen:true,music_volume:0},names:['Miso','Clover'],
    watered_ground:{'2:-4':{x:1,z:-2,radius:.65,until:18.3},
      '0:0':{x:0,z:0,radius:1.9,until:16.2}}})));
  const copies = new Map();
  const env = {ZEND_MIGRATION_ENABLED:'true',GARDEN_TRANSFERS:{
    async put(key, body) { copies.set(key,body); },
    async get(key) { const value=copies.get(key); return value ? {async json(){return JSON.parse(value);}} : null; },
    async delete(key) { copies.delete(key); },
  }};
  const call = (action, body, origin=format.HOME_ORIGIN, method='POST', config=env) => onRequest({
    params:{action},env:config,request:new Request(`${format.HOME_ORIGIN}/api/garden-transfer/${action}`,{
      method,headers:{Origin:origin,'Content-Type':'application/json'},
      ...(method==='POST'?{body:JSON.stringify(body)}:{})}),
  });
  for (const bytes of originals) {
    const sealed=await sealCopy(bytes);
    const response=await call('create',sealed.body,format.SOURCE_ORIGIN);
    assert.equal(response.status,201);
    assert.equal(response.headers.get('cache-control'),'no-store');
    assert.equal(response.headers.get('access-control-allow-origin'),format.SOURCE_ORIGIN);
    const {token}=await response.json();
    assert.match(token,/^[A-Za-z0-9_-]{43}$/);
    assert(![...copies.values()][0].includes('Miso'),'Relay must never contain plaintext');
    for(let retry=0;retry<2;retry++) {
      const read=await call('read',{token}); assert.equal(read.status,200);
      const body=await read.json();
      assert.deepEqual(await unsealCopy(body,sealed.secret),bytes);
      await assert.rejects(unsealCopy({...body,ciphertext:body.ciphertext.slice(0,-2)+'AA'},sealed.secret));
      await assert.rejects(unsealCopy(body,format.base64(webcrypto.getRandomValues(new Uint8Array(32)))));
    }
    assert.equal((await call('read',{token},'https://attacker.test')).status,403);
    assert.equal((await call('read',{token},format.SOURCE_ORIGIN)).status,403);
    assert.equal((await call('create',sealed.body)).status,403);
    assert.equal((await call('ack',{token})).status,200);
    assert.equal((await call('ack',{token})).status,200,'Acknowledgement is retryable');
    assert.equal((await call('read',{token})).status,404);
  }
  assert.equal((await call('create',{},format.SOURCE_ORIGIN)).status,400);
  assert.equal((await call('create',null,format.SOURCE_ORIGIN)).status,400);
  assert.equal((await call('read',{token:'../invalid'})).status,400);
  assert.equal((await call('read',{},format.HOME_ORIGIN,'GET')).status,405);
  assert.equal((await call('read',{},format.HOME_ORIGIN,'POST',{})).status,503);
  const preflight=await call('create',null,format.SOURCE_ORIGIN,'OPTIONS');
  assert.equal(preflight.status,204);
  assert.equal(preflight.headers.get('access-control-allow-headers'),'Content-Type');
  assert.equal((await call('create',null,'https://attacker.test','OPTIONS')).status,403);
  const sealed=await sealCopy(originals[1]);
  const {token}=await (await call('create',sealed.body,format.SOURCE_ORIGIN)).json();
  for(const [key,body] of copies) copies.set(key,JSON.stringify({...JSON.parse(body),expires:Date.now()-1}));
  assert.equal((await call('read',{token})).status,410);
  assert.equal(copies.size,0);
  assert.equal((await call('create',{iv:'a'.repeat(16),ciphertext:'a'.repeat(8*1024*1024)},format.SOURCE_ORIGIN)).status,413);
  for(const data of [{version:2,plants:null},{version:3,plants:[]},{version:2,plants:[],names:{}},
    {version:2,plants:[{id:0,plot:0,pos:[0,0],age:1,water:1}]},
    {version:2,plants:[],player:[0]}, {version:2,plants:[],climate:{values:[]}},
    ...[2,null,[],{x:1,z:2,radius:.65},{x:1,z:2,radius:'wide',until:18.3}]
      .map(patch=>({version:2,plants:[],watered_ground:{'2:4':patch}}))]) {
    assert.throws(()=>format.validateSave(new TextEncoder().encode(JSON.stringify(data))));
  }
  await assert.rejects(unsealCopy({},sealed.secret),/incomplete/);
  const next=()=>new Response('GAME');
  for(const [enabled,path,result] of [['true','/','MOVE'],['true','/moving','MOVE'],['true','/moving.html','MOVE'],['true','/?stay=1','GAME'],['false','/','GAME'],['true','/pack/000.bin','GAME']]) {
    const request=new Request(`${format.SOURCE_ORIGIN}${path}`);
    const response=await middleware.onRequest({request,next,env:{ZEND_MIGRATION_ENABLED:enabled,ASSETS:{fetch:async r=>{
      assert.equal(new URL(r.url).pathname,'/moving');return new Response('MOVE');
    }}}});
    assert.equal(await response.text(),result);
    if(result==='MOVE') {
      assert.equal(response.status,200,'Serve the moving asset without redirecting away from its security policy');
      assert.equal(response.headers.get('cache-control'),'no-store');
      assert(response.headers.get('content-security-policy').includes('https://zend.garden'));
    } else if(path.startsWith('/?') || path==='/') {
      assert(response.headers.get('content-security-policy').includes("script-src 'self' 'wasm-unsafe-eval'"));
      assert.equal(response.headers.get('referrer-policy'),'no-referrer');
    }
  }
  for(const path of ['/moving','/moving.html','/moving?stay=1']) {
    const response=await middleware.onRequest({request:new Request(format.SOURCE_ORIGIN+path),env:{ZEND_MIGRATION_ENABLED:'false'},next});
    assert.equal(response.status,302);
    assert.equal(response.headers.get('location'),format.SOURCE_ORIGIN+'/?stay=1');
    assert.equal(response.headers.get('cache-control'),'no-store');
  }
  console.log('MIGRATION_RESULT: PASS — encrypted v1/v2 copies, corruption/key checks, CORS, expiry, retries, size limits, recovery route and rollback switch');
})().catch(error=>{console.error(error);process.exitCode=1;});
