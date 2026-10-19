import { MAX_SECONDS, reply, sameOrigin, enabled, boundedJSON, signSession, verifySession, UPDATE_SQL, PURGE_SQL } from '../../server/analytics.js';
import { admitted, publishActivity, SNAPSHOT_PURGE_SQL } from '../../server/public_activity.js';

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
        || !['desktop', 'touch'].includes(body.device) || body.running !== 0) return reply({ error: 'invalid' }, 400);
      if (!await admitted(env, 'starts', now)) return reply({ error: 'busy' }, 429);
      const session = await env.GARDEN_STATS.prepare(`INSERT INTO sessions (id, started, last_seen, version, device, running)
        VALUES (?1, ?2, ?3, ?4, ?5, ?6) ON CONFLICT(id) DO UPDATE SET id = excluded.id
        RETURNING id, started, version, device`)
        .bind(body.id, now, now, body.version, body.device, 0).first();
      const token = await signSession(session, env.SESSION_SECRET);
      // Expired summaries are removed during new visits and dashboard reads.
      waitUntil(publishActivity(env, now).catch(() => {}));
      if (Math.random() < 0.02) waitUntil(env.GARDEN_STATS.batch([
        env.GARDEN_STATS.prepare(PURGE_SQL).bind(now - MAX_SECONDS),
        env.GARDEN_STATS.prepare(SNAPSHOT_PURGE_SQL).bind(Math.floor(now / 86400) * 86400 - 86400),
      ]).catch(() => {}));
      return reply({ token, elapsed: Math.max(0, now - session.started) }, 201);
    }
    if (body.action !== 'report' || Object.keys(body).some(key => !['action', 'token', 'running', 'advancing', 'game_minutes', 'ended'].includes(key))
      || !seconds(body.running) || !seconds(body.advancing) || body.advancing > body.running + 5 || typeof body.ended !== 'boolean') return reply({ error: 'invalid' }, 400);
    // Virtual time includes accelerated days and instant reduced-motion skips,
    // so it must not be constrained to wall seconds. Still bound its size/type.
    if (body.game_minutes !== undefined && (!Number.isInteger(body.game_minutes)
      || body.game_minutes < 0 || body.game_minutes > MAX_SECONDS * 1440)) return reply({ error: 'invalid' }, 400);
    let session;
    try { session = await verifySession(body.token, env.SESSION_SECRET, now); }
    catch { return reply({ error: 'token' }, 403); }
    if (body.running > now - session.started + 60) return reply({ error: 'invalid-time' }, 400);
    if (!await admitted(env, 'reports', now)) return reply({ error: 'busy' }, 429);
    await env.GARDEN_STATS.prepare(UPDATE_SQL).bind(body.running, body.advancing, body.ended ? 1 : 0, now, session.id, body.game_minutes ?? null).run();
    waitUntil(publishActivity(env, now).catch(() => {}));
    return reply({ ok: true });
  } catch { return reply({ error: 'unavailable' }, 503); }
}
