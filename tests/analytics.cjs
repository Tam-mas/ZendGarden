const assert = require('node:assert/strict');
const fs = require('node:fs');
const { webcrypto } = require('node:crypto');
global.crypto = webcrypto;
(async () => {
  const { createTelemetry } = await import('../web/telemetry.js');
  const { onRequest: collect } = await import('../functions/api/session.js');
  const { onRequest: stats } = await import('../functions/api/stats.js');
  const { verifySession, MAX_SECONDS } = await import('../server/analytics.js');
  let clock = Date.now(), interval, fail = false;
  const events = new Map(), packets = [], starts = [];
  const id = '22ac027d-9279-4c34-a258-7c13076c1e2d';
  const client = createTelemetry({ now: () => clock, device: 'desktop', randomID: () => id,
    every: (callback, ms) => { interval = callback; assert.equal(ms, 120000); return 1; }, cancel() {},
    on: (name, callback) => events.set(name, callback),
    fetch: async (url, options) => {
      assert.equal(url, '/api/session'); assert.equal(options.credentials, 'omit');
      const packet = JSON.parse(options.body); packets.push(packet);
      if (fail) throw new Error('offline');
      return Response.json(packet.action === 'start' ? { token: 'fixture' } : { ok: true });
    },
  });
  client.advance(100); await client.report(); assert.equal(packets.length, 0, 'No collection before game start');
  client.setVersion(63); client.start(); await new Promise(setImmediate);
  assert.equal(packets[0].id, id); assert.equal(packets[0].version, 63);
  assert.deepEqual([...events.keys()], ['pagehide', 'pageshow'], 'No focus, visibility or input listeners');
  clock += 10 * 60000; client.advance(20); await client.report();
  assert.equal(packets.at(-1).running, 600, 'Elapsed time includes a throttled background interval');
  assert.equal(packets.at(-1).advancing, 20, 'Simulation time is counted separately');
  fail = true; clock += 120000; interval(); await new Promise(setImmediate);
  fail = false; clock += 120000; await client.report();
  assert.equal(packets.at(-1).running, 840, 'Failed reports do not lose cumulative time');
  events.get('pagehide')(); await new Promise(setImmediate); assert.equal(packets.at(-1).ended, true);
  events.get('pageshow')({ persisted: true }); await new Promise(setImmediate); assert.equal(packets.at(-1).ended, false);
  clock -= 60000; await client.report(); assert.equal(packets.at(-1).running, 840, 'A clock reversal cannot subtract time');
  await client.stop(); const count = packets.length; client.advance(30); await client.report(); assert.equal(packets.length, count);

  const rows = new Map(), writes = [];
  const env = { ZEND_ANALYTICS_ENABLED: 'true', SESSION_SECRET: 's'.repeat(43), STATS_PASSWORD: 'p'.repeat(43),
    GARDEN_STATS: { prepare(sql) { return { bind(...values) { return {
      async first() {
        const [id, started, last_seen, version, device] = values;
        if (!rows.has(id)) rows.set(id, { id, started, version, device });
        starts.push({ sql, values }); return rows.get(id);
      },
      async run() { writes.push({ sql, values }); return { success: true }; },
    }; } }; }, async batch() { return [
      { results: [{ sessions: 1, running: 600 }] }, { results: [{ median: 600 }] },
      { results: [] }, { results: [] }, { results: [] },
    ]; } },
  };
  const call = (handler, body, { origin = 'https://zend.garden', host = origin, auth, method = 'POST', config = env, type = 'application/json' } = {}) => handler({ env: config, waitUntil: promise => promise,
    request: new Request(host + '/api/session', { method, headers: { Origin: origin, 'Content-Type': type, ...(auth ? { Authorization: 'Bearer ' + auth } : {}) }, ...(method === 'POST' ? { body: JSON.stringify(body) } : {}) }) });
  const start = { action: 'start', id, version: 63, device: 'desktop', running: 0 };
  const response = await call(collect, start); assert.equal(response.status, 201);
  const { token } = await response.json();
  assert.equal((await verifySession(token, env.SESSION_SECRET, Math.floor(Date.now() / 1000))).id, id);
  const retry = await call(collect, { ...start, running: 100 });
  assert.equal((await retry.json()).token, token, 'A retry retains the original start and identity'); assert.equal(rows.size, 1);
  const report = { action: 'report', token, running: 0, advancing: 0, ended: false };
  assert.equal((await call(collect, report)).status, 200);
  assert.equal((await call(collect, { ...report, token: token.slice(0, -4) + 'AAAA' })).status, 403);
  assert.equal((await call(collect, { ...report, running: 10000 })).status, 400, 'Reject totals exceeding elapsed server time');
  assert.equal((await call(collect, { ...report, advancing: 100 })).status, 400);
  assert.equal((await call(collect, { ...report, running: NaN })).status, 400);
  assert.equal((await call(collect, { ...start, garden: { plants: [] } })).status, 400, 'Reject unexpected fields');
  assert.equal((await call(collect, { ...start, running: MAX_SECONDS + 1 })).status, 400);
  assert.equal((await call(collect, start, { origin: 'https://other.test', host: 'https://zend.garden' })).status, 403);
  assert.equal((await call(collect, start, { origin: 'https://preview.pages.dev' })).status, 503);
  assert.equal((await call(collect, start, { config: { ...env, ZEND_ANALYTICS_ENABLED: 'false' } })).status, 503);
  assert.equal((await call(collect, start, { method: 'GET' })).status, 405);
  assert.equal((await call(collect, { ...start, extra: 'x'.repeat(3000) })).status, 413);
  assert.equal((await call(collect, start, { type: 'text/plain' })).status, 400);
  assert.equal((await call(stats, { days: 7 })).status, 401);
  assert.equal((await call(stats, { days: 7 }, { auth: 'wrong' })).status, 401);
  assert.equal((await call(stats, { days: 7 }, { auth: env.STATS_PASSWORD, origin: 'https://other.test', host: 'https://zend.garden' })).status, 403);
  assert.equal((await call(stats, { days: '7; DROP TABLE sessions' }, { auth: env.STATS_PASSWORD })).status, 400);
  const privateResponse = await call(stats, { days: 7 }, { auth: env.STATS_PASSWORD });
  assert.equal(privateResponse.status, 200); assert.equal(privateResponse.headers.get('cache-control'), 'no-store');
  assert.equal(privateResponse.headers.get('access-control-allow-origin'), null);
  const dashboard = await privateResponse.json(); assert.equal(dashboard.totals.median, 600);
  assert(!JSON.stringify(dashboard).includes(id), 'Dashboard returns aggregates, never session records');
  for (const file of ['web/telemetry.js', 'server/analytics.js', 'functions/api/session.js']) {
    assert(!/visibilityState|visibilitychange|hasFocus|document\.hidden|['"]blur['"]|['"]focus['"]|localStorage|sessionStorage|userAgent|CF-Connecting-IP/i.test(fs.readFileSync(file, 'utf8')), file);
  }
  assert(!fs.readFileSync('scripts/garden.gd', 'utf8').includes('JavaScriptBridge.eval'), 'Browser bridge must work under strict CSP');
  console.log('ANALYTICS_RESULT: PASS — background elapsed time, independent simulation totals, retries, closure/resume, signed sessions, origin/body limits, private aggregates and no attention tracking');
})().catch(error => { console.error(error); process.exitCode = 1; });
