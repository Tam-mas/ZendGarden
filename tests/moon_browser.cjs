// Run the real lunar checks through the packaged WebGL game; no real saves/profile.
const assert=require('node:assert/strict');
const fs=require('node:fs/promises');
const path=require('node:path');
const {chromium}=require(process.env.PLAYWRIGHT_MODULE || 'playwright');
(async()=>{
 const root=path.resolve('build/web');
 const server=require('node:http').createServer(async(req,res)=>{
  const url=new URL(req.url,'http://127.0.0.1');
  const filename=path.resolve(root,'.'+(url.pathname==='/'?'/index.html':url.pathname));
  if(!filename.startsWith(root+path.sep)){res.writeHead(403);res.end();return;}
  try {
   let body=await fs.readFile(filename);
   if(url.pathname==='/loader.js'){
    let source=body.toString();
    assert(source.includes('`--browser-save-check=${session.expected}`'),'Loader argument injection anchor changed');
    source=source.replace('`--browser-save-check=${session.expected}`','`--browser-save-check=${session.expected}`, \'--moon-test\'');
    source=source.replace('onExit: () => { void window.ZendTelemetry?.stop(); release(); location.reload(); },','onExit: () => { release(); },');
    body=Buffer.from(source);
   }
   res.setHeader('Content-Type',({'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm','.json':'application/json','.css':'text/css'})[path.extname(filename)]||'application/octet-stream');
   res.end(body);
  }catch(error){res.writeHead(404);res.end(String(error));}
 });
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 const origin='http://127.0.0.1:'+server.address().port;
 let browser,timer;
 try {
  browser=await chromium.launch({headless:true,channel:'chrome'});
  const context=await browser.newContext({viewport:{width:1440,height:900}});
  await context.route('**/*',async route=>{
   const url=new URL(route.request().url());
   if(url.origin!==origin)return route.abort();
   if(url.pathname==='/api/session')return route.fulfill({json:{ok:true,token:'local-moon-fixture'}});
   return route.continue();
  });
  const page=await context.newPage();
  const errors=[];
  let finish;
  const complete=new Promise(resolve=>{finish=resolve;});
  page.on('pageerror',error=>errors.push(error.message));
  page.on('console',message=>{
   const text=message.text();
   if(/SCRIPT ERROR|ERROR:/.test(text))errors.push(text);
   if(/MOON_RENDER_COVERAGE|MOON_IN_GAME_RESULT/.test(text))console.log(text);
   if(text.includes('MOON_IN_GAME_RESULT:'))finish(text);
  });
  await page.goto(origin);
  await page.getByRole('button',{name:'Enter the garden',exact:true}).click();
  const result=await Promise.race([complete,new Promise((_,reject)=>{timer=setTimeout(()=>reject(new Error('WebGL lunar checks timed out')),240000);})]);
  assert(result.endsWith('[]'),result);
  assert.deepEqual(errors,[]);
  await page.screenshot({path:'/tmp/zend-moon-browser.png'});
  console.log('MOON_BROWSER_RESULT: PASS — WebGL phase pixels, orbit, mode saves, pauses, transition and guide');
  await context.close();
 }finally{
  clearTimeout(timer);
  if(browser)await browser.close();
  await new Promise(resolve=>server.close(resolve));
 }
})().catch(error=>{console.error(error);process.exitCode=1;});
