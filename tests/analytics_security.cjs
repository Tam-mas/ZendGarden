const assert = require('node:assert/strict');
(async () => {
  const { onRequest: activity } = await import('../functions/api/activity.js');
  const { onRequest: collect } = await import('../functions/api/session.js');
  const { SNAPSHOT_READ_SQL, ADMISSION_SQL } = await import('../server/public_activity.js');
  const { createTelemetry } = await import('../web/telemetry.js');
  let reads = 0, writes = 0, clock = Date.UTC(2026, 9, 19, 23, 59, 50);
  const originalNow = Date.now; Date.now = () => clock;
  const storage = new Map(), pending = [];
  const payload = { days: 90, totals: { sessions: 1, longest: 120 }, devices: [{ name: 'touch', sessions: 1 }] };
  const env = { ZEND_ANALYTICS_ENABLED: 'true', SESSION_SECRET: 's'.repeat(43),
    GARDEN_STATS: { prepare(sql) { return { bind(...args) { return {
      async first() {
        if (sql === ADMISSION_SQL) return null; // Exhausted creation budget.
        assert.equal(sql, SNAPSHOT_READ_SQL, 'Public reads must never query session rows');
        reads++; return { payload: JSON.stringify(payload) };
      }, async run() { writes++; throw new Error('Public read attempted a write'); },
    }; } }; } },
  };
  globalThis.caches = { default: {
    async match(key) { return storage.get(key.url)?.clone(); },
    async put(key, value) { storage.set(key.url, value.clone()); },
  } };
  const call = async (suffix = '', config = env, host = 'https://zend.garden') => activity({
    request: new Request(host + '/api/activity' + suffix, { headers: { 'Cache-Control': 'no-cache' } }),
    env: config, waitUntil: promise => pending.push(promise),
  });
  try {
    const first = await call(); await Promise.all(pending);
    assert.equal(first.headers.get('cache-control'), 'public, max-age=0, s-maxage=10');
    assert.deepEqual(await first.json(), payload);
    payload.totals.longest = 999;
    const second = await call('?days=1&nonce=anything');
    assert.equal((await second.json()).totals.longest, 120, 'Incoming variants must share the published cache');
    assert.equal(reads, 1); assert.equal(writes, 0);
    assert.equal((await call('', { ...env, ZEND_ANALYTICS_ENABLED: 'false' })).status, 503, 'Disable must precede cache lookup');
    assert.equal((await call('', env, 'https://preview.pages.dev')).status, 503);
    clock += 20000; await call(); assert.equal(reads, 2, 'Midnight must use a new canonical key');
    const denied = await collect({ env, waitUntil() {}, request: new Request('https://zend.garden/api/session', {
      method: 'POST', headers: { Origin: 'https://zend.garden', 'Content-Type': 'application/json' },
      body: JSON.stringify({ action: 'start', id: '22ac027d-9279-4c34-a258-7c13076c1e2d', version: 74, device: 'touch', running: 0 }),
    }) });
    assert.equal(denied.status, 429); assert.equal(writes, 0);

    // An offline start cannot turn its unverified elapsed time into a long visit.
    let offline = true; const packets = [];
    const client = createTelemetry({ now: () => clock, device: 'touch', randomID: () => 'fixture',
      every: () => 1, cancel() {}, on() {}, fetch: async (_url, options) => {
        const packet = JSON.parse(options.body); packets.push(packet);
        if (offline) return new Response('{}', { status: 503 });
        return Response.json(packet.action === 'start' ? { token: 'fixture', elapsed: 0 } : { ok: true });
      } });
    client.setVersion(74); client.start(); await new Promise(setImmediate);
    clock += 89 * 86400000; offline = false; await client.report();
    assert.equal(packets.at(-2).running, 0); assert.equal(packets.at(-1).running, 0);
    clock += 120000; client.advance(20); await client.report();
    assert.equal(packets.at(-1).running, 120); assert.equal(packets.at(-1).advancing, 20);
    console.log('ANALYTICS_SECURITY_RESULT: PASS — canonical edge cache, midnight rollover, read-only publication, admission budget and offline start rebasing');
  } finally { Date.now = originalNow; delete globalThis.caches; }
})().catch(error => { console.error(error); process.exitCode = 1; });
