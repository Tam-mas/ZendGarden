import { publishActivity, SNAPSHOT_PURGE_SQL } from '../server/public_activity.js';
import { PURGE_SQL } from '../server/analytics.js';

// No HTTP handler, public route, API token or dashboard password. This worker's
// only binding is the statistics database and it runs once per UTC day.
export default {
  async scheduled(event, env) {
    const now = Math.floor(event.scheduledTime / 1000);
    const day = Math.floor(now / 86400) * 86400;
    await publishActivity(env, now);
    await env.GARDEN_STATS.batch([
      env.GARDEN_STATS.prepare(PURGE_SQL).bind(day - 90 * 86400),
      env.GARDEN_STATS.prepare(SNAPSHOT_PURGE_SQL).bind(day - 86400),
    ]);
  },
};
