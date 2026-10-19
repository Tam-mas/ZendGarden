import { MAX_SECONDS, enabled, publicReply, PURGE_SQL } from '../../server/analytics.js';
import { PUBLIC_TOTALS_SQL, MEDIAN_SQL, GROUP_SQL } from './stats.js';

const DAYS = 90;

// This endpoint is intentionally public. It returns only 90-day aggregate
// activity and broad device totals: no identifiers, rows, daily cohorts,
// game-version data, current activity, or response-generation timestamp.
export async function onRequest({ request, env }) {
  if (request.method !== 'GET') return publicReply({ error: 'method' }, 405);
  if (!enabled(request, env)) return publicReply({ error: 'disabled' }, 503);
  const now = Math.floor(Date.now() / 1000);
  const since = Math.floor(now / 86400) * 86400 - (DAYS - 1) * 86400;
  try {
    await env.GARDEN_STATS.prepare(PURGE_SQL).bind(now - MAX_SECONDS).run();
    const result = await env.GARDEN_STATS.batch([
      env.GARDEN_STATS.prepare(PUBLIC_TOTALS_SQL).bind(since),
      env.GARDEN_STATS.prepare(MEDIAN_SQL).bind(since),
      env.GARDEN_STATS.prepare(GROUP_SQL('device')).bind(since),
    ]);
    return publicReply({ days: DAYS,
      totals: { ...result[0].results[0], ...result[1].results[0] },
      devices: result[2].results });
  } catch { return publicReply({ error: 'unavailable' }, 503); }
}
