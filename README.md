# Zend Garden

**A quiet place to plant, grow, and make your own.**

Zend Garden is a cozy first-person gardening game set in a peaceful lake valley. Fill your plots with flowers, shrubs, trees, and produce; add paths and ornaments; and watch your garden change with the weather and seasons. Wander among your plants, welcome animal companions, or find a favourite view and take a photo.

There is no rush to keep everything perfect. Plants do not die from neglect, and garden requests have no deadlines. Tend a small patch or gradually build a dense, layered garden at your own pace.

The game is in development, and its source is publicly available as an **open-source release**.

## What you can do

- Grow **60 plant varieties**, including flowers, grasses, groundcover, shrubs, trees, Australian natives, and edible plants.
- Combine plants of different heights in the same area. Trees sit between the smaller planting positions, and each plant has a little natural variation in its mature height.
- Water, prune, harvest, move, and rearrange your planting as your garden develops.
- Earn petals through harvests and garden requests, discover plants, and unlock more growing space.
- Decorate with benches, lanterns, pots, ponds, pergolas, and other garden structures.
- Enjoy changing seasons, weather, birds, bees, butterflies, and animal companions.
- Use photo mode to explore freely and capture your favourite corners.

## Play on the web or host your own garden

The repository includes a browser export and an automatic Cloudflare Pages build. To publish it on your own domain, follow the [Cloudflare Pages setup guide](docs/cloudflare-pages.md). The browser edition supports keyboard and mouse, plus automatic touch controls for phones and tablets. It saves your garden on that device in browser storage.

## Getting started

These instructions run the game from source using the Godot editor.

### Requirements

- [Godot 4](https://godotengine.org/download/), standard edition. The project is configured for Godot 4.7 and has been tested with **Godot 4.7.2**.
- [Git](https://git-scm.com/downloads) and [Git LFS](https://git-lfs.com/) to download the game and its 3D assets.
- A computer that supports Godot's **Forward+** renderer.

The game has been tested on an Apple silicon Mac. Windows and Linux have not yet been verified. **Blender is not required to play**; the repository includes the exported models used by the game.

### Download and launch

Install Git and Git LFS, then run:

```sh
git lfs install
git clone https://github.com/Tam-mas/ZendGarden.git
cd ZendGarden
git lfs pull
```

The models and editable art files use Git LFS and add a few hundred megabytes to the download. Use the clone instructions above: a GitHub ZIP download may contain asset pointers instead of the models themselves.

1. Open Godot's Project Manager and choose **Import**.
2. Select `project.godot` from the downloaded folder.
3. Open the project and allow the initial asset import to finish.
4. Press **F5** to play.

On macOS, you can also use `Play Zend Garden.command` if Godot is installed as `/Applications/Godot.app`.

### Your first planting

Press **Tab** to open the menus and choose a plant from the seed selection. Aim down at a garden plot and click to plant where the preview appears. Switch to the watering tool to tend it, then keep exploring or press **G** to move on to the next morning. The in-game guide explains the tools and garden systems in more detail.

## Controls

| Control | Action |
| --- | --- |
| **W A S D** or **arrow keys** | Walk |
| **Mouse** | Look around |
| **Shift** | Walk faster |
| **Tab** | Open menus / return to looking around |
| **Left click** | Use the selected tool at the centre crosshair |
| **1–8** | Select wander, plant, water, prune, harvest, move, remove, or rake |
| **L** | Change the target plant layer where plants overlap |
| **G** | Advance to the next morning |
| **E** | Greet a nearby companion |
| **Q / E** while placing a structure | Rotate it |
| **Mouse wheel** | Adjust the field of view |
| **P** | Enter or leave photo mode |
| **W A S D / Q E** in photo mode | Fly horizontally / down and up |
| **Right mouse drag** in photo mode | Look around |
| **F12** or **Capture** | Save a screenshot |
| **Escape** | Open settings, dismiss the welcome guide, or leave photo mode |

## Life in the garden

A normal in-game day lasts about **10 minutes**, and each season lasts **12 days**. Different plants grow at different speeds, with sunlight, water, and the season affecting their progress. Dormant plants keep their growth progress, and a greenhouse can protect seasonal planting. Trees also provide shade for the plants beneath them.

You can advance to the next morning whenever you want. The garden does not progress while the game is closed, so you can return without having missed anything.

Settings include reduced motion, mouse sensitivity, independent left/right and up/down mouse inversion, field of view, separate audio volume controls, and an option to pause while menus are open.

### Pruning, paths, and visitors

Pruning and gathering a mature plant both add one item to **Your basket**, then the plant must regrow before yielding again. Decorative border plants provide one item per day through either tool. See your collected items in **Shop** or **Orders**; ready orders have an enabled Deliver button. Delivery consumes the requested items and awards petals once, with another request arriving two days later. **Sell spare harvest** keeps the items needed for current orders.

Outside garden beds, three pruning cuts remove a plant. Planted varieties recover one cut each morning; cleared decorative border plants stay cleared. Pruning inside beds remains safe. To clear lawn grass, use the rake: it leaves a grooved earth path, and upgraded rakes can widen an existing patch. Move or prune plants before raking underneath them. New patches can reveal up to four petals per day.

Tomato seeds cost **23 petals** to unlock. You can plant them in any season; they grow in **summer and autumn**, or year-round inside a greenhouse. The seed selection now explains when you need more petals.

Rabbits occasionally visit open areas. Kangaroo visits are currently disabled. Buy a **Beehive for 65 petals** from the shop and place it to attract its own daytime bees.

## Saves and photos

Your garden saves automatically every 20 seconds, when a new day starts, and when the game closes normally. You can also save manually from the menu.

The save file is named `garden_v1.json`; screenshots are stored in the `photos` folder alongside it. Standard save locations are:

| System | Garden data folder |
| --- | --- |
| macOS | `~/Library/Application Support/Godot/app_userdata/Zend Garden/` |
| Windows | `%APPDATA%\Godot\app_userdata\Zend Garden\` |
| Linux | `~/.local/share/godot/app_userdata/Zend Garden/` |

Some installations use different locations; see [Godot's user data paths](https://docs.godotengine.org/en/stable/tutorials/io/data_paths.html). Back up your save before experimenting with development changes or starting a fresh garden.

## Feedback and contributions

Bug reports, ideas, and contributions are welcome as the project prepares for its open-source release. Use [GitHub Issues](https://github.com/Tam-mas/ZendGarden/issues) to report a problem or suggest an improvement. For a bug, include your operating system, Godot version, what you expected, and the steps needed to reproduce it. Screenshots are helpful for visual issues.

For code or art changes, keep each [pull request](https://github.com/Tam-mas/ZendGarden/pulls) focused and explain what changed and how you checked it. Discuss larger changes in an issue first so the scope is clear.

### Project layout

| Location | Contents |
| --- | --- |
| `project.godot` and `main.tscn` | Godot project and starting scene |
| `scripts/` | Gameplay, interface, terrain, weather, and companions |
| `shaders/` | Rendering effects |
| `assets/` | Models, textures, and other runtime assets |
| `art_source/` | Editable Blender files, generation scripts, and botanical references |
| `tests/` | Asset checks and game smoke tests |

### Checking changes

The test runner requires **zsh**, **Python 3**, **ripgrep**, and Godot. On macOS with Godot in `/Applications/Godot.app`, run:

```sh
zsh tests/run.sh
```

For another Godot installation, provide the executable path:

```sh
GODOT_BIN="/path/to/godot" zsh tests/run.sh
```

The runner checks assets, imports the project, and runs wildlife and gameplay checks. The gameplay test opens a visible game window and uses a separate test save. Keep the window visible while it runs.

### Working on plant models

The game uses exported `.glb` models. Editing or regenerating the source art requires Blender; the existing workflow has been tested with Blender 5.2.1. To rebuild the generated assets:

```sh
BLENDER_BIN="/path/to/blender" zsh art_source/rebuild.sh
```

On macOS, the script defaults to Blender in `/Applications/Blender.app`. Run heavy exports sequentially, then open Godot to import the updated assets. See the [botanical references](art_source/botanical_references.md) for the plant forms that guide the stylized models.

## License and release status

MIT licensed. Use, fork, modify or share. Its up to you

### Personal garden signs

Open **Shop → Custom garden sign** to write up to 64 characters and choose a text colour. Each sign costs 15 petals. Place it on the ground and use **Q/E** to rotate it; the lettering is readable from both sides. Use the **Edit sign** buttons in the Shop to change existing signs for free, or the usual move and remove tools to rearrange them. Your signs are saved with your garden.

### Playing on a phone or tablet

Touch controls appear automatically; landscape orientation gives you the most room. Use the left thumbstick to walk, drag the view to look around, and choose a tool from **Tools**. Aim with the centre dot and tap the labelled action button. Hold **Water** or **Rake** to repeat. Placement offers rotation and cancel buttons; lifting a plant or ornament offers **Undo lift** for 12 seconds.

**Garden** opens seeds, the shop, orders, settings, next morning and photo mode. Menus pause movement, and controls reset when the app loses focus. Text fields support the on-screen keyboard, and browser photos download to your device.

In **Settings**, choose Auto, Touch or Keyboard & mouse controls; switch to a left-handed layout; adjust touch-control size, look sensitivity and inversion; and choose graphics quality or 3D resolution. The automatic mobile graphics preset reduces rendering resolution, disables sun shadows, and limits distant decorative meshes. Menus stay at full resolution.

Mobile layouts and simultaneous touch input are covered by automated tests and browser emulation. Performance and on-screen keyboard behaviour still need testing on physical iOS and Android devices, particularly with large gardens. Saves stay with the browser profile and site address; they do not automatically sync across devices or domains.

## Shop reference

Prices are in petals. Select a structure in Shop, then aim at open ground to place it. **Q/E** rotates it; **Move** relocates it. **Remove** (formerly “Lift”) removes a plant or ornament; it does not raise the ground. Removing an ornament refunds its purchase price. Plants do not refund petals, but unlocked seeds stay available. Terrain raising is not currently a tool.

| Item | Price | Function |
| --- | ---: | --- |
| Path stone | 3 | Places one small limestone stone for a decorative border or path. |
| Terracotta pot | 25 | Decorative pot. |
| Garden bench | 45 | Decorative seating for a quiet garden corner. |
| Stone lantern | 55 | Glows after dusk. |
| Climbing arbor | 65 | Supports nearby climbing plants. |
| Timber pergola | 100 | Larger frame supporting nearby climbing plants. |
| Glass greenhouse | 120 | Lets plants within 4 metres grow year-round and protects their growing conditions. |
| Lily pond | 75 | Attracts frogs and dragonflies; can hold fish. |
| Bird bath | 40 | Birds land, dip and splash in daylight; nearby calls follow the nature-volume setting. |
| Beehive | 65 | Adds four daytime bees around the hive. |
| Custom garden sign | 15 | Places a sign with your text and colour; existing signs can be edited for free. |
| Stock nearest pond with fish | 20 | Adds decorative fish to an unstocked pond in the current garden area. |
| Soaker system | 45 per bed | From day 7, restores the bed’s plants’ water every morning. |
| Gentle auto-pruner | 45 per bed | From day 7, removes stress from the bed’s plants each morning; does not collect items. |
| Expand bed capacity | 65 | Adds 80 planting capacity to the current bed; repeatable. |
| Watering can upgrades | 45, then 90 | Wider watering area and a longer-lasting water supply. |
| Pruning shears upgrades | 45, then 90 | Wider pruning area and greater stress reduction. |
| Planting trowel upgrades | 45, then 90 | Shorter delay between planting actions. |
| Garden rake upgrades | 45, then 90 | Wider raked paths and more petals per new patch, within the four-petal daily limit. |
| Open next garden | Varies | Opens the next plot early and discovers three seed varieties; the shop shows its price. Plots also open as days pass. |

First tool upgrades unlock on day 3; second upgrades unlock on day 18. Seed varieties are bought in **Seeds**, where each variety’s unlock price is shown. Unlocking a variety lets you plant it repeatedly without paying for each plant.

Pressing **G** advances to the next morning with a 12-second transition. The reduced-motion setting retains its quick transition option.

### Inspecting shop models

Every shop item has an exported model in **`assets/shop/`**:

- Open a `.tscn` in Godot to inspect the complete scene, including lights and sign lettering.
- Import the matching `.glb` into Blender or a glTF viewer to inspect its geometry and materials. Sign lettering is a Godot label and is preserved in the `.tscn`, rather than the GLB.
- Examples: `greenhouse.tscn`, `bath.tscn`, `stone.tscn`, and their `.glb` counterparts.

The game currently builds these models from `scripts/garden_art.gd` (`furnishing`). These exports are inspection copies; editing one does not change the runtime model. After changing the generator, refresh the copies with:

```sh
godot --headless --path . --script tools/export_shop_models.gd
```

Bird-bath behaviour lives in `scripts/bath_life.gd`. Bath visitors leave at night, and calls fade with distance. The four starting beds have distinct gentle music themes: the beginning, waterside, woodland, and terrace. Later beds reuse these themes. Moving between beds crossfades the tracks; music and nature volume settings still apply. Original audio sources can be regenerated with `python3 tools/build_audio.py`.
