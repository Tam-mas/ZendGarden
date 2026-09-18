# Zend Garden

A playable first-person Godot 4 gardening game with an original Blender-built botanical library and a lake-country environment. Walk at eye level, look around with the mouse, and aim at soil to garden. The user’s reference images guide the richer planting and alpine-lake setting; they are not pasted onto the scenery.

## Clone from GitHub

The 3D models and editable Blender libraries use Git LFS. Install Git LFS, then clone with:

```sh
git lfs install
git clone https://github.com/Tam-mas/ZendGarden.git
cd ZendGarden
git lfs pull
```

A GitHub ZIP download may contain LFS pointers instead of usable models; cloning with Git LFS is the supported setup.

## Play

Double-click **Play Zend Garden.command** on this Mac, or open `project.godot` in Godot and press **F5**. The project uses Godot’s **Forward+** renderer, soft directional shadows, ambient occlusion, animated water, and a procedural cloud sky. Tested in Godot 4.7.2 on Apple M1; the revised test scene reached approximately 50 fps at 1280 × 800. This is a short scene measurement, not a guarantee for every garden size.

| Control | Action |
| --- | --- |
| W A S D | Walk relative to your view |
| Mouse | First-person look, with the pointer captured |
| Shift | Walk faster |
| Tab | Release the pointer and open menus / return to mouse-look |
| Left click | Use the active tool at the centre crosshair |
| 1–8 | Wander, choose seeds, water, prune, gather, move, lift, rake |
| L | Change the target layer in a shared planting cell |
| G | Six-second sunset → moving stars → sunrise, advancing exactly one day |
| E | Greet a nearby companion; rotate clockwise when placing/moving a structure |
| Q | Rotate a structure anticlockwise (15° steps) |
| Mouse wheel | Adjust field of view |
| P | Enter or leave photo mode |
| W A S D / Q E in photo mode | Fly horizontally / vertically |
| Right mouse drag in photo mode | Look around |
| F12 / Capture | Save a clean PNG screenshot |
| Escape | Release the pointer or leave photo/help mode |

Choose a seed from the menu to return to first-person planting. Aim down at soil within seven metres and click. A grid and plant preview appear during placement; the camera stays at your eye position. Open Shop with the released pointer to select an ornament, then click the world to resume aiming. The body mesh is hidden so it cannot obscure your view. The character retains ground and boundary collision.

## Blender visual overhaul

- **60 exported botanical models**, with seeded species forms, shaped leaf surfaces, veins, branching stems, bark, petals, seed disks and fruit. Different families include daisy/sunflower heads, rose-like layered blooms, lavender spikes, foxglove bells, hydrangea clusters, arching grasses, lobed maple leaves, narrow willow/eucalyptus foliage and distinct produce forms.
- Modelled foliage and blooms remain separate so the original growth, gathering and reblooming systems continue to work. Existing plant IDs, plot coordinates, currencies and saves are retained.
- **A fully 3D lake valley**, with eroded mountain ridges, woodland canopy, small distant settlements and moving water. A low wall at the northern terrace provides a lookout. The lake is easiest to see from that terrace or free photo mode.
- Textured loam, irregular limestone bed edging and stepping stones, a garden pavilion, dense meadow grass and permanent perennial borders.
- All new assets and surface maps were generated locally in **Blender 5.2.1** and exported as glTF. No external model packs or unverified licences are required.

This is a substantial art pass toward the references, with stylized original models. It does not reproduce the photographic detail of the lake image or the production art fidelity of the garden screenshot.

The rolling meadow includes short path grass, medium meadow grass and taller clustered patches. Mountains use rock/vegetation/snow blending based on height and slope, with triplanar stone detail and denser mixed conifer/broadleaf forests.

## Growing a garden

- **60 varieties** across flowers, grasses and groundcover, shrubs, trees, Australian natives, and produce. Plants use Blender-built botanical geometry, species palettes, different growth durations, habitat preferences and wildlife attractions. The editable generators use species-specific organs and silhouettes, with research notes in [botanical references](art_source/botanical_references.md). Menu portraits are rendered from the same models used in the garden.
- **Four real planting layers** can overlap: groundcover, flower, shrub and canopy. They consume 1, 2, 4 and 7 capacity. New trees snap half a cell between the lower planting rows, with 1.15 m between trunks. Their canopy shades underplanting. Press L to target a layer; old tree positions remain selectable.
- Each bed has a capacity meter, including the proposed plant's cost before placement. Full beds can be expanded, or plants can be lifted and relocated. Seeds are never consumed.
- **Denser beds:** 0.4 m planting spacing (529 lower-layer positions per bed, up from 225) and twice the previous capacity (220, 260, 280 and 340 before expansions; four times the original). Old planting positions remain valid. Plants can overlap naturally across four layers for packed borders.
- **Individual plant heights:** each planting grows toward a saved mature height between 80% and 120% of its model’s normal height. Width stays unchanged. The difference grows in smoothly from the seedling stage; moving, gathering, pruning and reloading preserve the plant’s own height. Existing saves acquire stable variations automatically.
- New seeds show a disturbed-soil mound and coloured stake until the juvenile plant becomes readily visible. Markers move, lift and reload with the planting.
- Growth progresses through small seedlings, leafy juveniles, buds and mature flowers or fruit. One day lasts 150 seconds; pressing G plays a six-second overnight time-lapse. Water and pruning improve growth. Neglected plants slow down but never die.
- **Seasons and weather:** spring, summer, autumn and winter each last 12 game days. Varieties need 2–28 ideal growing days; some only grow during their listed seasons. Off-season plants keep their progress and rest. Greenhouses allow year-round growth. Clear skies, cloud, rain, mist and winter snow transition gradually with clouds, light, fog and precipitation. Rain waters plants and adds soft rain audio. Weather state is saved.
- All gardening stays available at night. Original generated audio combines a gentle pentatonic score, wind, water, birds and night insects.
- Four connected plots open on days 7, 18 and 36, or sooner through purchase. Bridges cross the water channels, and a hillside path connects the remaining gardens. Bed climates are sun, waterside and shade. The garden has rolling terrain, subdivided soil beds and matching collision, surrounded by procedural hills and mountains.
- Discover a seed variety every third morning. New plots also grant three varieties. Earn petals through harvests and requests rather than passive daily gifts.

## Tools, decoration and neighbours

Watering cans and shears have two purchased upgrades that extend care radius. Better cans leave plants watered for longer; improved shears remove more stress. Trowels reduce the delay between placements; rakes tidy wider path patches and find more petals.

Early bed automation costs 45 petals per system and supplies water or pruning each morning. Bed expansions cost 65 petals for another 80 capacity; previously purchased expansions receive the same increase. Future areas also use the doubled budget.

The shed sells pots, benches, lanterns, arbors, pergolas, greenhouses, ponds and bird baths. Climbing plants extend vines onto nearby support frames. Greenhouses protect plants within four metres from unsuitable conditions. Ponds can be stocked with animated fish. Placed ornaments can be moved or lifted; lifting returns their full price.

Neighbours request flowers and produce with no deadlines. Gathering a mature plant yields an item and allows it to bloom again. Fulfil notes for petals or sell your basket directly.

Flower clusters attract bees and butterflies; natives attract native birds; trees and bird baths attract songbirds; ponds attract frogs and dragonflies. Moss attracts nocturnal fireflies. Name your cat and dog in the Guide. Original Blender-built tabby and collie models have articulated legs, heads, ears and tails, walking gaits, breathing, resting poses and tail motion. They follow paths over bridges and need no care.

## Save and photos

The game saves every 20 seconds, on a new day, on manual Save, and when closing normally. Save writes use a temporary file before replacement. No real-world time passes while the game is closed.

Godot's local user data directory on this Mac is:

`~/Library/Application Support/Godot/app_userdata/Zend Garden/`

- `garden_v1.json`: your garden, progression, inventory, names, plants, structures and weather. The filename is retained; format version 2 backs up and accepts original version 1 saves and preserves each plant’s percentage of maturity when migrating to longer growth times.
- `photos/`: photo-mode PNGs.
- `smoke-test-save.json`: isolated automated test data; never replaces your garden.

## Validation

Run `./tests/run.sh`. Override `GODOT_BIN` for another Godot executable. This launches the actual renderer and verifies:

- 60-species catalogue, four coexisting layers, duplicate-layer rejection and bed capacity;
- automated growth, free plot progression, neighbour rewards and greenhouse protection;
- fish creation, planting, watering, pruning, moving and lifting through the action dispatcher;
- bridge accessibility, grid coordinates and a complete save/reload round trip.

The script fails on engine script errors as well as failed assertions. It writes daytime and nighttime screenshots to `captures/`. Test runs use their own save file.

## Project structure

- `scripts/garden.gd`: player, first-person camera, UI, gameplay, persistence and integration checks.
- `scripts/landscape.gd`: landscape integration, borders, water, grass and collisions.
- `assets/plants/`: 60 runtime botanical glTF files.
- `assets/environment/`: the Blender environment export.
- `assets/textures/`: original surface and leaf-vein maps.
- `shaders/`: procedural cloud sky and moving water.
- `scripts/garden_art.gd`: procedural plants, structures, companions and mountains.
- `scripts/catalogue.gd`: plant and furnishing definitions.
- `scripts/soundscape.gd`: original runtime-generated stereo audio.

This is a self-contained playable source build with original Blender art. It has not been packaged as a signed standalone application or tested on platforms beyond this Mac.

## Editable Blender sources

- `art_source/botanical_library.blend`: the 60 species laid out in a labelled workshop grid.
- `art_source/lake_garden.blend`: terrain, mountain forest, settlements, paths, masonry and pavilion.
- `art_source/build_botanicals.py`: repeatable botanical generation and glTF export.
- `art_source/build_environment.py`: repeatable environment and texture generation.
- `art_source/plant_specs.json`: species inputs; `botanical_manifest.json`: export inventory.
- `art_source/workshop.blend`: the isolated initial workshop; the original Blender scene is preserved separately.

`art_source/.gdignore` prevents Godot from auto-importing the editable `.blend` library. Runtime assets are the explicit `.glb` exports. Blender is not needed to play.

To rebuild locally, run `art_source/rebuild.sh`, then let Godot reimport the changed assets. The scripts currently use this workspace’s absolute path. Asset validation checks that all 60 species and the environment exist and that no default Blender cube or extra scene was exported. Gameplay tests also check eye-level camera position, crosshair-to-soil targeting, upward-ray rejection and Tab cursor switching.

## Blender startup troubleshooting

The crash report dated **14 September 2026, 09:56:32** corresponds to a Codex-launched background process that exited during restricted-environment startup. Subsequent Blender launches with normal OS access completed successfully. A later read-only check also opened both source libraries (120 botanical meshes and 9 environment meshes), with no missing textures.

Automation should launch Blender with approved normal OS access and should not repeatedly retry restricted launches. This finding applies to that reported process; it does not rule out a separate interactive rendering or add-on crash. No Blender preferences or installed add-ons were changed during diagnosis.

Run this read-only source check from a normal Terminal if needed:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --disable-autoexec --python tests/check_blender_sources.py
```

Zend Garden itself runs from exported assets; Blender can stay closed while you play.

## First-person polish update

- While walking, a compact corner readout replaces the large menu panels. Tab restores the full menus and tool bar. Bed capacity and plant care details appear when you aim with a gardening tool.
- Four original Blender hand-tool models now appear during planting, watering, pruning/gathering and raking, with a brief action animation. Their editable source is `art_source/hand_tools.blend`; regenerate them with `art_source/build_tools.py`.
- Invalid planting previews turn coral and explain the capacity, occupancy or root-spacing constraint before placement.
- Birds, bees, butterflies, dragonflies and frogs have distinct silhouettes and more appropriate scale and flight heights.
- The distant landscape recedes farther from the garden, and the lake uses soft directional ripples instead of a repeating checker pattern.

The updated asset and gameplay checks pass; this test scene reached approximately 57 fps on the local M1. Screenshots include `captures/first-person-watering.png` and `captures/lake-lookout.png`.

## September terrain and seasons validation

`tests/run.sh` exercises the normal gardening controls and save round trip, then checks a 170-flower packed bed, 340 groundcover placements and 48 canopy placements, capacity limits, seasonal dormancy and resumption, greenhouse protection, rain transitions and watering, snow, raised-soil and bridge collision, companion bridge routes, seed-marker lifecycle and old-save growth migration. It writes additional screenshots into `captures/`.

Companion sources: `art_source/build_companions.py`, `art_source/companions.blend`, and `assets/companions/{cat,dog}.glb`. All companion art is original. `art_source/rebuild.sh` includes these exports. Blender exports remain sequential and use the isolated workshop; Blender is not needed while playing.

The landscape is split into forest sections for manageable imports and distance detail. Tests complete the import pipeline before launch and compare imported mountain/forest index counts with the GLB source, preventing stale scenery from passing validation. Measured performance uses one running game; multiple debug sessions compete for the same GPU.

## Wood and parchment interface

The sidebar, tool buttons, shop, Guide, input fields and photo controls use original wood, brass and parchment textures. Duplicate header navigation has been removed; use the sidebar tabs. Photo mode remains on P and is explained in the Guide. The seed catalogue is a two-column grid of clickable plant portraits with names and capacity/unlock details. Portraits are rendered from the actual 60 game models.

Q/E and the rotation buttons turn an ornament by 15° while placing or moving it, including rotation in place. Saved ornaments retain their angle; earlier saves default to their original orientation. The day-skip animation accelerates the game-time-driven sun, clouds and star sphere, fades captions, and eases the camera upward and back. Repeated G presses during it are ignored, so dawn rewards and growth happen once.

Rebuild UI textures with `python3 art_source/build_menu_textures.py`. Render plant portraits with Godot using `--path . --script art_source/render_plant_cards.gd` (requires a renderer). The theme uses the operating system’s serif font with fallbacks and bundles no proprietary font files. `tests/ui_update.gd` checks rotation persistence, card selection, header cleanup and the complete time-lapse; acceptance captures are in `captures/`.

## Enclosed lake valley

The main lake is clipped to the actual terrain contour, with curved coves and shoreline stones. Southern wooded headlands and outer ridges enclose the scenery beyond the garden. The original Blender generator writes `art_source/landscape_validation.json` to verify water stays inside the terrain boundary. `tests/shoreline.gd` checks the imported scenery and captures south, southwest, southeast and north views; the import checks also compare the new lake, rocks and ridge meshes with their GLB source.

## A welcoming pace

First launch shows a five-page illustrated welcome with real plant portraits, a quiet modal backdrop, back/continue/skip controls, and a paused garden. Settings can replay it. Existing gardens see it once after updating; completing or skipping it is saved. Settings also persist request pop-ups, reduced motion, inverted vertical look, menu-time pause, sound volume, mouse sensitivity and field of view. Escape opens Settings; Tab retains normal menu access. Reduced motion replaces the accelerated-night camera sequence with an immediate morning.

New gardens begin with 80 petals. Mornings no longer grant petals; raking finds at most four daily and spare harvest sells for half its former value (minimum one). Existing balances and discoveries are retained. Beds open freely on days 7, 18 and 36 (or can be purchased earlier), with three seed gifts each. Another seed arrives every third day. First tool upgrades arrive on day 3, automatic bed care on day 7, and master tools on day 18. Completing 3, 8 and 15 neighbour requests awards three seed discoveries each. Guide lists the journey.

The first request is available immediately; two more arrive on days 3 and 5. A delivered request is replaced two mornings later. No request expires. New arrivals have a dismissible popup linking to Orders and an unread dot; popups can be disabled independently. Cats and dogs explore safe garden routes, rest, visit separately, and occasionally return together.

`tests/experience.gd` checks no passive day-skip income, request timing and opt-out/dismissal, welcome pausing, saved preferences and separate/shared companion routines. It captures the welcome and settings screens in `captures/`.

## Continuing gardens and step-up walking

Beyond the original four beds, another bed opens every 12 days starting on day 48. Connected rows are created as needed, with one unopened row ahead; there is no fixed final bed. Deterministic positions preserve planting and structure saves, and bed care supports multi-digit bed numbers. The old northern wall has a gateway into the new rows. Unopened beds can be explored but cannot be planted until unlocked.

The player checks headroom and a walkable landing before stepping over low obstacles up to 0.48 m high. Limestone paths and edging now have collision. Bridges remain walkable even when the bed across them is unopened. `tests/walking.gd` traverses both original bridges in both directions, steps over a low obstacle, walks through the expansion gateway, and checks planting/saving in bed 11. Run `--walk-test` for this isolated regression using the smoke-test save.


## Ground, planting and daylight

A full day now lasts ten minutes (600 seconds). The visible sun and shadow-casting directional light use the same continuously advancing clock; G still skips to morning. The sky combines three independently drifting cloud decks with sun-facing density shading, darker undersides and high wisps. These are layered sky-shader clouds, not volumetric geometry.

Raking creates a subdivided, textured ground patch sampled to the terrain at every vertex, and clears procedural grass inside it. Saved paths rebuild the same way; upgraded patch widths are persisted. Meadow and soil materials mix rotated texture scales and normal-map detail to soften repetition.

Seeds can be planted on dry ground outside beds within an unlocked garden area, sharing its capacity. Occupancy, tree spacing and save behavior still apply. Water, bridge routes and structures are excluded. `tests/ground_finish.gd` checks these rules, path heights and saved widths, ten-minute timing and changing sun orientation, and writes ground/cloud captures. `--ground-test` runs it with the isolated smoke-test save.

## Pruning, a fresh start and sound

Pruning gives plants a shorter, narrower silhouette over a brief transition. Trim strength is saved and fades over roughly four suitable growing days; repeated pruning refreshes the same shape rather than endlessly shrinking a plant. Growth age and harvest readiness are preserved.

Settings offers “Start a new garden…” with a keep/cancel option and an explicit reset confirmation. Confirming saves and renames the current garden to a timestamped `.before-restart-…json` backup before reloading a fresh day-one garden. It resets plants, petals, unlocks and settings. A backup failure cancels the reset.

The original generated soundtrack now varies melodic phrases, timbres, rests and chord changes, with sparse soft bells and less regular birdsong. Music and nature volume are independently adjustable beneath the master volume. Path stones use smoother rounded profiles rather than random sharp vertical offsets. `tests/pruning.gd` checks visible pruning, regrowth, persistence, restart cancellation and backup integrity with the isolated test save.
