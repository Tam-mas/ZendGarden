# Publish Zend Garden on Cloudflare Pages

This repository can build the browser game directly in Cloudflare Pages. You do not need a game server, Blender, a separate asset bucket, or a Cloudflare API token in GitHub.

## Connect the repository

1. In the Cloudflare dashboard, open **Workers & Pages**, create a **Pages** project, and choose the option to import an existing Git repository. Choose Pages rather than a Worker.
2. Connect GitHub and select **Tam-mas/ZendGarden**.
3. Use these build settings:

| Setting | Value |
| --- | --- |
| Production branch | `main` |
| Framework preset | **None** |
| Root directory | Leave blank (repository root) |
| Build command | `python3 tools/build_web.py` |
| Build output directory | `build/web` |

The repository also declares `build/web` in `wrangler.jsonc`, so Pages reads the output directory from version control. The build command and repository root must still be set in the dashboard.

4. Save and deploy. The first build downloads Godot 4.7.2, its export templates, and the runtime models from Git LFS. Allow several minutes.
5. Open the supplied `*.pages.dev` address and click **Enter the garden**. Test walking, planting, and returning to a saved garden before sharing the link.

Subsequent pushes to `main` trigger a new production deployment. Cloudflare can also create preview deployments for other branches. See [Cloudflare's Git integration guide](https://developers.cloudflare.com/pages/get-started/git-integration/).

## Connect your domain

After the first successful deployment:

1. Open your Pages project and select **Custom domains → Set up a custom domain**.
2. Enter the domain or subdomain where you want the game, such as `garden.example.com`.
3. Follow Cloudflare's DNS instructions and wait for the domain and HTTPS certificate to become active.

Associate the domain with the Pages project before adding a DNS record manually. Apex domains (such as `example.com`) need their DNS zone on Cloudflare; a subdomain can use a CNAME with an external DNS provider. See [Cloudflare's custom-domain instructions](https://developers.cloudflare.com/pages/configuration/custom-domains/).

## Browser behaviour

- Use a current desktop browser with WebGL 2 and a keyboard and mouse. Touch controls are not implemented.
- The browser uses Godot's Compatibility renderer. Some lighting effects differ from the native Forward+ version.
- The first load downloads approximately 126 MiB. Loading time and frame rate depend on the connection and computer; large gardens can be demanding.
- Saves live in browser storage for that exact site, browser, and device. Clearing site data removes them. Saves on a preview URL, the `pages.dev` address, and your custom domain are separate. They are not cloud-synced or shared with the desktop game.
- Use the in-game save button before leaving. Browsers may close a tab without sending the native game's normal shutdown event.
- The game is single-threaded, so it does not require cross-origin isolation headers. The procedural audio uses stream playback; browser audio may pause until the player interacts with the game.

## How the build works

- `export_presets.cfg` defines the Web release export and its launch page.
- `tools/build_web.py` installs project-local build tools as needed, fetches runtime Git LFS assets, checks Godot release archive checksums, imports resources, and exports the game.
- `web/` contains the welcome page, loader, and Pages HTTP headers.
- The generated site goes into `build/web/`. Build tools and output are ignored by Git and do not need committing.
- The asset pack is divided into compressed pieces. The browser checks and joins them before starting Godot. The engine's WASM file is also compressed. The browser explicitly decompresses these files; it does not depend on HTTP content-encoding headers. This keeps each deployed file below [Pages' 25 MiB asset limit](https://developers.cloudflare.com/pages/platform/limits/).
- `_headers` sets MIME types, cache behaviour, and security headers. Deploy the complete output folder, not selected files.
- A top-level `404.html` prevents missing game assets from being treated as SPA routes.

GitHub Actions also builds and validates the site on pushes and pull requests. A successful run provides a `zend-garden-pages` artifact for inspection or manual upload; it does not deploy to your Cloudflare account. The connected Pages project handles deployment.

## Build and preview locally

On Linux x86-64, the script downloads Godot automatically:

```sh
python3 tools/build_web.py
python3 tests/check_web_build.py
python3 tools/serve_web.py
```

On macOS, point it at your installed Godot 4.7.2:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot python3 tools/build_web.py
python3 tests/check_web_build.py
python3 tools/serve_web.py
```

Open `http://localhost:8080`. The preview server serves the compressed bytes directly, just like Pages. Python 3.10+ and Git are required; install Git LFS locally on macOS. The cloud build installs Git LFS if it is missing on Linux x86-64.

If a build fails, inspect the Cloudflare build log or `build/import.log` and `build/export.log` locally. Missing models usually indicate a Git LFS download problem. Download or decompression errors in the browser can indicate an interrupted transfer or an old deployment being cached. Try a full reload after confirming the deployment finished.

## Homepage shows “This path is outside the garden”

If the homepage returns this message and `/shell.html` is accessible, Pages has published the source `web/` folder instead of the generated game. Set the root directory to the repository root (blank), the build command to `python3 tools/build_web.py`, and the output directory to `build/web`. Save the settings and retry the latest production deployment. Do not use `web` as the output directory: it contains the page template, not the exported game.
