import { MAX_SECONDS, reply, sameOrigin, enabled, authorized, boundedJSON, PURGE_SQL } from '../../server/analytics.js';

export const TOTALS_SQL = `SELECT COUNT(*) AS sessions, COALESCE(SUM(running),0) AS running,
 COALESCE(SUM(advancing),0) AS advancing, COALESCE(AVG(running),0) AS average,
 COALESCE(MAX(running),0) AS longest,
 COALESCE(SUM(running >= 300),0) AS over5, COALESCE(SUM(running >= 900),0) AS over15,
 COALESCE(SUM(running >= 1800),0) AS over30,
 COALESCE(SUM(last_seen >= ?2 AND ended = 0),0) AS recent
 FROM sessions WHERE started >= ?1`;
export const MEDIAN_SQL = `SELECT COALESCE(AVG(running),0) AS median FROM
 (SELECT running FROM sessions WHERE started >= ?1 ORDER BY running
 LIMIT 2 - (SELECT COUNT(*) FROM sessions WHERE started >= ?1) % 2
 OFFSET MAX(0, ((SELECT COUNT(*) FROM sessions WHERE started >= ?1) - 1) / 2))`;
export const DAILY_SQL = `SELECT strftime('%Y-%m-%d', started, 'unixepoch') AS day,
 COUNT(*) AS sessions, SUM(running) AS running, SUM(advancing) AS advancing
 FROM sessions WHERE started >= ?1 GROUP BY day ORDER BY day`;
export const GROUP_SQL = column => `SELECT ${column} AS name, COUNT(*) AS sessions,
 SUM(running) AS running, SUM(advancing) AS advancing FROM sessions
 WHERE started >= ?1 GROUP BY ${column} ORDER BY sessions DESC`;

export async function onRequest({ request, env }) {
  if (request.method !== 'POST') return reply({ error: 'method' }, 405);
  if (!sameOrigin(request)) return reply({ error: 'origin' }, 403);
  if (!await authorized(request, env.STATS_PASSWORD)) return reply({ error: 'unauthorized' }, 401);
  if (!enabled(request, env)) return reply({ error: 'disabled' }, 503);
  let body;
  try { body = await boundedJSON(request); } catch { return reply({ error: 'invalid' }, 400); }
  if (![1, 7, 30, 90].includes(body.days) || Object.keys(body).some(key => key !== 'days')) return reply({ error: 'invalid' }, 400);
  const now = Math.floor(Date.now() / 1000);
  // UTC start-day cohorts, including today, give stable daily comparisons.
  const since = Math.floor(now / 86400) * 86400 - (body.days - 1) * 86400;
  try {
    await env.GARDEN_STATS.prepare(PURGE_SQL).bind(now - MAX_SECONDS).run();
    const result = await env.GARDEN_STATS.batch([
      env.GARDEN_STATS.prepare(TOTALS_SQL).bind(since, now - 300),
      env.GARDEN_STATS.prepare(MEDIAN_SQL).bind(since),
      env.GARDEN_STATS.prepare(DAILY_SQL).bind(since),
      env.GARDEN_STATS.prepare(GROUP_SQL('device')).bind(since),
      env.GARDEN_STATS.prepare(GROUP_SQL('version')).bind(since),
    ]);
    return reply({ generated: now, days: body.days, totals: { ...result[0].results[0], ...result[1].results[0] },
      daily: result[2].results, devices: result[3].results, versions: result[4].results });
  } catch { return reply({ error: 'unavailable' }, 503); }
}
