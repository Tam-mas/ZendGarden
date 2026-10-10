# Anonymous garden statistics

Production at `https://zend.garden` reports anonymous session totals to the Pages
Function `/api/session`. The private dashboard is at `/stats`. Its password is
stored as a Cloudflare encrypted secret; the ignored local `.stats-access.txt`
contains the owner's copy. The password stays in dashboard memory until it is
locked or closed. It is never placed in a URL, cookie or browser storage.

## Measurements

- **Sessions:** a new random ID for each loaded garden, held only in memory.
  Reloading or returning later creates another session; these are not unique
  people or daily active users.
- **Game-open time:** elapsed wall time after the game loads. Includes background
  tabs, paused menus and device sleep. Browser throttling catches up on the next
  successful report. It measures elapsed open time, not CPU execution or attention.
- **Garden advancing:** accumulated Godot frame time while the garden clock
  advances. Excludes the welcome panel, photo mode, day transition and menus that
  pause the clock. An unattended garden can still advance. No browser focus or
  visibility signals are observed.
- **Average, median, longest and 5/15/30-minute sessions:** based on game-open time.
  Includes unfinished sessions with their latest reported totals.
- **Daily comparisons:** UTC session-start cohorts. A session's entire duration
  belongs to its start day, including any time after midnight. Date ranges use the
  same rule. These are not calendar-day usage totals.
- **Devices and versions:** desktop/touch capability and the existing game update
  number. No user-agent string, precise screen size or device fingerprint.
- **Reporting recently:** unfinished sessions with a report in the last five
  minutes. This is not a live player or attention count.

Reports are sent on load, every two minutes, and best-effort on closing. A hidden
browser may suspend JavaScript or networking. No server extrapolation is made:
elapsed time appears when another report arrives. If a browser is killed or never
resumes, time after its last report is unknown. Advancing-time reports are batched
every five seconds inside Godot, so closing can lose up to five seconds.
Failed analytics requests never block loading, play or saves. There is no tracking
on the welcome/download screen. Previews, native builds and other hostnames do not
collect production statistics.

## Storage and private access

Cloudflare D1 `zend-garden-stats` contains one row per session with a random ID,
server-derived start and last-report times, coarse device category, update number,
two cumulative durations and a closing flag. Repeat starts return the same session;
repeated or out-of-order totals cannot inflate time. Signed session tokens stop
arbitrary updates to other session IDs. Public metrics remain best-effort client
telemetry, not tamper-proof accounting.

The collector stores no IP addresses, names, email, save contents, referrer, visited
areas, keystrokes, mouse movements, focus events or persistent visitor identifier.
Cloudflare necessarily receives ordinary HTTP connection metadata; these functions
do not copy it into the statistics database or log request payloads. No third-party
analytics script or tracking cookie is added.

Summaries older than 90 days are excluded from reports and purged during dashboard
reads and periodic new sessions. An idle database may retain expired rows until
the next purge. D1's own backups follow Cloudflare's Time Travel retention.

## Configure or restore

1. Create a D1 database with `wrangler d1 create zend-garden-stats`; set its ID in
   `wrangler.jsonc` under `GARDEN_STATS`. The production database is already listed.
2. Run `wrangler d1 execute zend-garden-stats --remote --file analytics/schema.sql`.
   The schema is idempotent and changes no player saves.
3. In Pages → `zendgarden` → Settings → Variables and Secrets, set production
   encrypted secrets `SESSION_SECRET` and `STATS_PASSWORD` to separate random
   values of at least 32 characters. Do not commit these values. They must exist
   before the deployment that uses them. `wrangler pages secret bulk` is also
   supported. Rotating `SESSION_SECRET` stops existing sessions reporting;
   rotating `STATS_PASSWORD` revokes the old dashboard password.
4. Deploy `main` through the existing Pages Git integration. Wrangler supplies the
   D1 binding and enable flag. Production hostname is explicitly checked; previews
   have no database binding and collection is disabled.
5. Open `/stats` and unlock it with the owner password. No Cloudflare API token is
   sent to the browser or needed by the dashboard.

Set `ZEND_ANALYTICS_ENABLED` to `false` in the repository and redeploy to pause
collection. The garden continues to load. The old transfer R2 bucket and local
recovery archives are not deleted by this change; they are no longer bound or read.

Run `node tests/analytics.cjs`, `python3 tests/analytics_sql.py` and
`node tests/save_storage.cjs` for the collector, authentication, timing, real SQL
and save-validator checks. `tests/analytics_browser.cjs` uses isolated Chrome
profiles to check real IndexedDB saves, session locks, strict CSP and the dashboard.
`tests/analytics_game.cjs` checks the timing bridge and menu behaviour in the actual
exported Godot game with an isolated existing save.
The regular build validates deployment files and absence of retired transfer assets.
