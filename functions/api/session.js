import { MAX_SECONDS, reply, sameOrigin, enabled, boundedJSON, signSession, verifySession, UPDATE_SQL, PURGE_SQL } from '../../server/analytics.js';

export async function onRequest({ request, env, waitUntil }) {
  if (request.method !== 'POST') return reply({ error: 'method' }, 405);
  if (!sameOrigin(request)) return reply({ error: 'origin' }, 403);
  if (!enabled(request, env)) return reply({ error: 'disabled' }, 503);
  let body;
  try { body = await boundedJSON(request); }
  catch (error) { return reply({ error: 'invalid' }, error.message === 'size' ? 413 : 400); }
  const now = Math.floor(Date.now() / 1000);
  const seconds = value => Number.isInteger(value) && value >= 0 && value <= MAX_SECONDS;
  try {
    if (body.action === 'start') {
      if (Object.keys(body).some(key => !['action', 'id', 'version', 'device', 'running'].includes(key))
        || typeof body.id !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(body.id)
        || !Number.isInteger(body.version) || body.version < 1 || body.version > 100000
        || !['desktop', 'touch'].includes(body.device) || !seconds(body.running)) return reply({ error: 'invalid' }, 400);
      const session = await env.GARDEN_STATS.prepare(`INSERT INTO sessions (id, started, last_seen, version, device, running)
        VALUES (?1, ?2, ?3, ?4, ?5, ?6) ON CONFLICT(id) DO UPDATE SET id = excluded.id
        RETURNING id, started, version, device`)
        .bind(body.id, now - body.running, now, body.version, body.device, body.running).first();
      const token = await signSession(session, env.SESSION_SECRET);
      // Expired summaries are removed during new visits and dashboard reads.
      if (Math.random() < 0.02) waitUntil(env.GARDEN_STATS.prepare(PURGE_SQL).bind(now - MAX_SECONDS).run().catch(() => {}));
      return reply({ token }, 201);
    }
    if (body.action !== 'report' || Object.keys(body).some(key => !['action', 'token', 'running', 'advancing', 'ended'].includes(key))
      || !seconds(body.running) || !seconds(body.advancing) || body.advancing > body.running + 5 || typeof body.ended !== 'boolean') return reply({ error: 'invalid' }, 400);
    let session;
    try { session = await verifySession(body.token, env.SESSION_SECRET, now); }
    catch { return reply({ error: 'token' }, 403); }
    if (body.running > now - session.started + 60) return reply({ error: 'invalid-time' }, 400);
    await env.GARDEN_STATS.prepare(UPDATE_SQL).bind(body.running, body.advancing, body.ended ? 1 : 0, now, session.id).run();
    return reply({ ok: true });
  } catch { return reply({ error: 'unavailable' }, 503); }
}
