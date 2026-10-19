import { enabled, publicReply, reply } from '../../server/analytics.js';
import { SNAPSHOT_READ_SQL } from '../../server/public_activity.js';

// This endpoint is intentionally public. It returns only 90-day aggregate
// activity and broad device totals: no identifiers, rows, daily cohorts,
// game-version data, current activity, or response-generation timestamp.
export async function onRequest({ request, env, waitUntil }) {
  if (request.method !== 'GET') return reply({ error: 'method' }, 405);
  if (!enabled(request, env)) return reply({ error: 'disabled' }, 503);
  const now = Math.floor(Date.now() / 1000);
  const day = Math.floor(now / 86400) * 86400;
  // Query strings, cookies and incoming cache directives cannot create variants
  // or force a live query. Old cached snapshots expire at the UTC day boundary.
  const key = new Request(`https://zend.garden/api/activity?day=${day}`);
  const cache = globalThis.caches?.default;
  try {
    const cached = await cache?.match(key);
    if (cached) return cached;
    // Exactly one indexed, read-only lookup. Never fall back to raw sessions.
    const snapshot = await env.GARDEN_STATS.prepare(SNAPSHOT_READ_SQL).bind(day).first();
    if (!snapshot) return reply({ error: 'unavailable' }, 503);
    const response = publicReply(JSON.parse(snapshot.payload), 200, day + 86400 - now);
    if (cache) {
      const write = cache.put(key, response.clone()).catch(() => {});
      if (waitUntil) waitUntil(write); else await write;
    }
    return response;
  } catch { return reply({ error: 'unavailable' }, 503); }
}
