# Moving gardens from zend.tammas.com to zend.garden

The migration is live as of 1 October 2026. Both domains use the existing
`zendgarden` Pages project. The private `zend-garden-transfers` bucket is bound to
production, with public access disabled and a one-day cleanup rule for `moves/`.
`wrangler.jsonc` is the source of truth for the flag and binding; preview deployments
keep migration off and have no production bucket binding. Dashboard-only changes
will not survive a deployment that uses this configuration.

## Production rollout record

- Original working production deployment: `380fb57a-c1fd-4a9d-be0d-f95bc249f7b3`
  ([original build](https://380fb57a.zendgarden.pages.dev)).
- Verified new game with transfer disabled: [bda12c02](https://bda12c02.zendgarden.pages.dev).
- Active migration deployment: [5c27f60f](https://5c27f60f.zendgarden.pages.dev).
- An isolated Chrome profile verified the actual live R2 create/read/delete flow,
  six-second automatic move, exact-byte import, Godot startup, unchanged source
  bytes, the `?stay=1` recovery route, and retained new-domain progress on repeat visits.
- The production security policy forbids JavaScript eval. Save-result callbacks
  use direct JavaScriptBridge calls, and actual-runtime tests apply that policy.
- Pages canonicalizes `.html` asset URLs. The middleware fetches `/moving`
  internally and covers both `/moving` and `/moving.html`, keeping the player on
  a response whose policy allows the new-domain relay. With migration off, those
  old-domain routes return to `?stay=1`.

The source changes must be merged into the Git-connected `main` branch before its
next automatic deployment; deploying the old main tree would replace this rollout.

The HTTP `www.zend.garden` address redirects to the apex, but HTTPS returned a
Cloudflare 525 during rollout. That pre-existing HTTPS/redirect configuration needs
attention in the dashboard or a separate token with DNS/redirect permissions;
the Wrangler login used here has Pages/R2 access and zone lookup only. The canonical
`https://zend.garden` address works and holds migrated saves.

## What players see

At the old address, a quiet panel says:

> Your little garden is moving to its new cozy home at zend.garden.

The page reads the old save without starting Godot. It prepares a copy, leaves the
message visible for six seconds, then navigates to the new home. Players can go
immediately, download a backup, or stay at the old address instead.

At the new home, the copy is checked and stored before the game can start. A short
arrival note asks players to bookmark zend.garden. Its Continue button opens the
game without another entry click. If a different garden already exists here, players
choose which to continue and can download both copies. Subsequent visits from the
old address keep the new site's latest progress instead of repeatedly importing
the old snapshot. No-save visitors go to the new home without an import.

## One-time Cloudflare setup

1. In R2, create a **private** bucket named `zend-garden-transfers`. Keep public
   access disabled. No public bucket domain or bucket CORS setting is needed;
   the Pages Function provides the narrowly allowed cross-domain requests.
2. Under that bucket's **Settings → Object Lifecycle Rules**, add an enabled rule
   for prefix `moves/` that deletes objects after **one day**. Unclaimed links stop
   working after fifteen minutes in the function, independently of the lifecycle.
   Claimed objects are deleted after the local import receipt is stored. R2's
   lifecycle removes abandoned encrypted objects later; its deletion is not an
   exact fifteen-minute timer. See [Cloudflare's lifecycle documentation](https://developers.cloudflare.com/r2/buckets/object-lifecycles/).
3. In the root `wrangler.jsonc`, replace the empty `r2_buckets` array with:

   ```json
   [{ "binding": "GARDEN_TRANSFERS", "bucket_name": "zend-garden-transfers" }]
   ```

   The binding must be on the Pages deployment serving **zend.garden**, where the
   transfer API runs. Preview environments should use a separate bucket if enabled;
   keep their migration flag off otherwise (as configured here). Bindings are supported in the config
   file and dashboard: [Cloudflare's Pages binding guide](https://developers.cloudflare.com/pages/functions/bindings/).
4. Deploy once with `ZEND_MIGRATION_ENABLED` still `"false"`. Verify the ordinary
   game loads at zend.garden and that `/api/garden-transfer/status` reports false.
   Both domains can use the same Pages project. If they use separate projects,
   deploy the reader/middleware assets to the old project too. The old project
   does not need a bucket binding; the reader always calls the new site's API.
5. Remove any edge, Bulk Redirect, Page Rule, or `_redirects` rule that immediately
   sends zend.tammas.com to zend.garden. The old HTTPS page must run before leaving
   its origin. Keep the existing www.zend.garden redirect to zend.garden.
6. Set `ZEND_MIGRATION_ENABLED` to `"true"` in the config and deploy the new-domain
   project first. Confirm its status endpoint reports true. Then enable/deploy the
   old-domain project, if separate. With a single project this happens together.
7. Verify a disposable garden in a **separate browser profile** at the old HTTPS
   address: save, close the game tab, visit the old root, move, enter at the new
   address, and check the plants and settings. Revisit the old root after making
   new progress to confirm it keeps the new garden. Visit `https://zend.tammas.com/?stay=1`
   to confirm the original is available. Do not clear the main browser's site data
   to perform these checks.

The existing Git-connected Pages build discovers the root `functions/` directory.
Keep the build command `python3 tools/build_web.py` and output `build/web`.
Dashboard drag-and-drop of static files alone cannot deploy these functions.
For a CLI deployment, run `wrangler pages deploy build/web` **from the repository
root**, with the correct existing Pages project selected, so it can compile
`functions/`. Do not create a new project accidentally.

DNS does not need changing if both HTTPS addresses already reach their respective
Pages deployments. Keep the old hostname and certificate active for returning
players and recovery. No save exists on the DNS server or in the Pages asset pack.

For an anonymous public upload endpoint, configure a Cloudflare rate-limit rule
on POST `/api/garden-transfer/create` appropriate to traffic (for example twenty
requests per minute per IP). The endpoint checks the allowed origin, format and
size, but an Origin header alone is not authentication against non-browser clients.

## Save safety and failure handling

- The old reader opens `/userfs` **without requesting a schema version**. It aborts
  database creation if no database exists, uses only read-only transactions, and
  never starts Godot, upgrades storage, writes a migration marker, or deletes a
  source record. It reads `FILE_DATA` at
  `/userfs/godot/app_userdata/Zend Garden/garden_v1.json`. A single legacy project
  folder is also supported; ambiguous legacy saves stop for help.
- Exact file bytes travel without conversion. The browser encrypts the envelope
  using AES-GCM with a random key and IV. R2 receives ciphertext only. The key
  travels in the URL fragment, which does not reach the HTTP server; page and
  function responses use `Referrer-Policy: no-referrer`. Tokens are random,
  stored under hashed keys, and sent to API reads/acknowledgements in POST bodies.
  The function does not log saves, tokens, keys or storage exceptions.
- On the new origin, `zend-garden-migration-v1/copies` retains the original under
  `original:<sha256>`, the staged `pending` copy, and a `before:<sha256>` copy of
  any active save being replaced. These bytes are kept in a **separate database**
  so Godot filesystem reconciliation and normal autosave cannot remove them.
- The staged copy is read back and checked. Promotion verifies the current target
  inside a read/write transaction before replacing it, then reads the active file
  back and compares every byte before recording completion. A failed write aborts
  the transaction. A retained pending copy can resume without the relay, including
  the checkpoint between active-file promotion and the completion receipt.
- An origin-scoped Web Lock prevents two updated game tabs, or a game and an
  import, from writing concurrently. Close older already-running game tabs before
  moving: a pre-migration build cannot participate in this new lock protocol.
  Unsupported browsers stop an import rather than proceeding without its lock.
- The game loader checks the stored save before engine initialization. Godot then
  checks the actual mounted file against that fingerprint and the supported save
  version/catalogue/plot references. If mounting fails or yields the wrong file,
  it stops before world creation and disables saves. It cannot silently start a
  fresh garden and autosave over the imported copy.
- A completed receipt prevents repeated stale imports. If a previously moved
  garden is now missing/unreadable, another transfer offers explicit recovery
  instead of replacing a readable current garden. Save schema versions remain 1/2;
  the player update counter is independent of save schema.

## Rollback

Set `ZEND_MIGRATION_ENABLED` back to `"false"` in the relevant Pages projects and
redeploy. The old root serves the game again; the transfer API declines new
operations. The old save was never changed by migration. `?stay=1` bypasses the
moving page immediately, without waiting for a rollout change. Keep a known working
old deployment available if the game build itself needs rolling back.

Do not clear site data, drop IndexedDB databases, remove the old custom domain, or
delete local copies as part of rollback. Disabling the relay does not undo gardens
already imported at the new address. Post-move progress remains on the new origin;
the old garden is the source snapshot, not a live mirror. A return transfer of new
progress to an older game release needs its own compatibility review.

Recovery copies can be inspected/exported in browser developer tools under
IndexedDB → `zend-garden-migration-v1` → `copies`. Do not paste save contents,
moving tokens or fragment keys into logs or issue reports. Downloading a backup
adds an independent copy; all browser copies can still be lost if site data is
cleared or the device fails. Normal operation stays in the same browser, profile
and device; this is a move, not account-based cloud sync.

## Verification

```sh
node tests/migration.cjs
node tests/web_loader.cjs
PLAYWRIGHT_MODULE=/path/to/playwright node tests/migration_browser.cjs
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot python3 tools/build_web.py
python3 tests/check_web_build.py
python3 tests/check_security_build.py
PLAYWRIGHT_MODULE=/path/to/playwright node tests/migration_game.cjs
npx wrangler pages functions build functions --outfile /tmp/zend-migration-worker.mjs --build-output-directory build/web
# Explicit opt-in; all browser storage is in disposable profiles.
ZEND_LIVE_CHECK=1 PLAYWRIGHT_MODULE=/path/to/playwright node tests/migration_live.cjs
```

The browser harness uses disposable profiles, intercepted HTTPS fixture domains,
the real IndexedDB implementation and the actual function handlers with an
in-memory relay. It covers Chrome and WebKit, source-byte preservation, automatic
navigation, conflicts and both choices, storage/relay failures, checkpoint recovery,
open-tab locks, repeat imports, empty browsers and the off switch. The game check
loads the actual export, then deliberately prevents Godot from mounting browser
storage to verify that startup halts without overwriting the save. Production R2
and custom-domain routing are covered by the opt-in disposable-profile live check.
