// Exercise the browser loader using compressed responses without encoding headers.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { gzipSync } = require('node:zlib');
const { webcrypto } = require('node:crypto');
const elements = new Map();
const context = vm.createContext({
  Response, Request, URL, Blob, DecompressionStream, Uint8Array, crypto: webcrypto,
  console, location: { href: 'https://example.test/' }, window: {},
  document: { getElementById(id) {
    if (!elements.has(id)) elements.set(id, { addEventListener() {} });
    return elements.get(id);
  } },
});
vm.runInContext(fs.readFileSync('web/loader.js', 'utf8'), context);
(async () => {
  const bytes = Buffer.from('GDPC fixture payload');
  const hash = Buffer.from(await webcrypto.subtle.digest('SHA-256', bytes)).toString('hex');
  for (const payload of [gzipSync(bytes), bytes]) {
    context.fetch = async url => url === 'pack.json'
      ? Response.json({ size: bytes.length, chunks: [{url: 'pack/000.bin', size: bytes.length, sha256: hash}] })
      : new Response(payload);
    assert.deepEqual(Buffer.from(await context.loadPack()), bytes);
  }
  context.fetch = async url => url === 'pack.json'
    ? Response.json({size: bytes.length, chunks: [{url:'pack/000.bin', size:bytes.length, sha256:hash}]})
    : new Response(gzipSync(Buffer.from('corrupt payload')));
  await assert.rejects(context.loadPack(), /incomplete/);
  const original = async () => new Response(gzipSync(bytes));
  context.window.fetch = original;
  await context.initEngine({ async init() {
    assert.deepEqual(Buffer.from(await (await context.window.fetch('index.wasm')).arrayBuffer()), bytes);
    assert.deepEqual(Buffer.from(await (await context.window.fetch('other.bin')).arrayBuffer()), gzipSync(bytes));
  } });
  assert.equal(context.window.fetch, original);
  await assert.rejects(context.initEngine({async init(){throw new Error('test failure');}}), /test failure/);
  assert.equal(context.window.fetch, original);
  console.log('PASS: gzip and decoded assets, corruption detection, scoped WASM loading, and fetch restoration');
})().catch(error => { console.error(error); process.exitCode = 1; });
