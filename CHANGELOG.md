# Changelog

### [2026-09-27 15:50] Changed

**Tech:** `README.md`, `docs/player-guide.md`, `docs/development.md`, `web/shell.html`, `build_environment.py` — player-facing introduction, welcome-page controls and denser mountain woodland.

**Dev:** Rewrite the README around the 106-plant game, its tools, visitors and creative play, moving detailed controls and development instructions into linked guides. Remove the requested welcome-page phrases and show arrow keys for movement. Add 24,000 deterministic, spaced trees across all four background directions, using the runtime landscape proportions for slope rejection, a varied treeline and clearings. Preserve the original forest, lake, terrain and hamlet placement; omit unused forest UVs to keep the environment within its existing asset budget. Extend forest coverage checks and add a separate matched woodland review mode.

**Plain:** The public page explains the game more clearly, and the mountain slopes have much fuller woodland.

**Why:** Helps new players understand the garden and makes its surroundings feel more alive.

### [2026-09-27 14:01] Added

**Tech:** `botanical_expansion_forms.py`, `build_botanical_expansion.py`, `botanical_expansion.blend`, `GardenCatalogue` — 46 detailed botanical assets and catalogue entries, for 106 total.

**Dev:** Append IDs 60–105 for the approved 40 plants plus broccoli, cauliflower, capsicum, Brussels sprouts, leek and hemp. Model species-specific culms, needles, fans, compound/toothed leaves, petals, stamens and fruit; embed pigment, normal and roughness maps, including striped roses and mottled gum bark. Preserve original IDs/assets and Grasses entries, add growth/season metadata and jasmine climbing support, generate portraits, and extend asset/import/UI checks to the full catalogue. Keep editable expansion sources separate, share geometry primitives without scene side effects, and rebuild the two libraries sequentially. Research and rendering workflows are documented alongside the sources.

**Plain:** Adds 46 new detailed plants with recognisable shapes and colours, including bamboo varieties, redwoods, snow gums, roses, jasmine, fruit trees, vegetables and hemp.

**Why:** Gives the garden a wider, more believable range of planting choices while preserving existing gardens.

### [2026-09-27 13:00] Added

**Tech:** `GardenTools.gather`, `repeat_mouse`, `garden.gd`, `touch_controls.gd` — area gathering, independent reach upgrades and held-input harvesting.

**Dev:** Gather checks every planted layer and nearby border plant in a visible square, using the existing readiness, regrowth, basket and daily border-yield rules. Hold left click or touch Gather to repeat at 0.12-second intervals while changing aim; empty passes remain quiet, and releasing input, opening menus, photo mode or day transitions stops collection. Separate 45/90-petal upgrades unlock on days 3/18 and widen the square from 1.3 to 2.1 to 2.9 metres. Existing saves default to the base Gather level. Added coverage for stacked plants, immature/out-of-range plants, repeat limits, mouse/touch input, purchase gates and save migration.

**Plain:** Hold Gather and sweep over ready plants to collect them together, with shop upgrades for a wider gathering area.

**Why:** Removes repeated clicking and makes dense, layered gardens easier to harvest.

### [2026-09-27 12:48] Added

**Tech:** `scripts/garden_tools.gd`, `garden_sculpt.gd`, `terrain.gd`, `garden.gd`, `art_source/build_wildlife.py` — manual watering boost, adjustable pruning footprint, sculpting hoe and lady beetles.

**Dev:** Manual ground watering grants a non-stacking 1.2× growth multiplier for one game day, with a refreshable saved timer and slope-following wet patches. Each shears upgrade increases the maximum square side by 10%; bracket keys and touch controls resize it within purchased limits. Added a Blender-built hoe with raise/lower modes (9 to equip, R to toggle), smooth local terrain offsets, nearby-tile mesh/collision updates, protected foundations/crossings and saved terrain. Planting, grass, paths, irrigation and decorative planting follow height edits. Added a textured, articulated seven-spot lady beetle that crawls near flowers/produce in daylight. Existing saves default to unchanged terrain. Expanded asset, keyboard/touch, growth, save and physical terrain checks; the full gameplay suite and Blender source validation pass.

**Plain:** Watering gives plants a temporary growth boost, upgraded pruners have an adjustable square, a new hoe reshapes slopes, and lady beetles visit planted gardens.

**Why:** Gives hands-on garden care a useful reward and adds more control over planting, terrain and wildlife.

### [2026-09-27 11:46] Changed

**Tech:** `art_source/botanical_detail.py`, `botanical_forms.py`, `scripts/garden_art.gd`, `shaders/leaf_wind.gdshader` — detailed models and PBR surface maps for all 60 catalogue plants.

**Dev:** Rebuilt all plant GLBs and the packed editable botanical library with curved/veined blades, cupped rose-family petals and lettuce leaves, finer flower centres and bells, irregular tree branching with connected stems and root flares, and smoother fruit with stems/calyces. Added deterministic colour, normal and roughness textures; retained these maps in the wind shader and enabled compressed embedded imports. Removed obsolete extracted texture copies and refreshed all 60 menu portraits. Added whole-catalogue PBR/geometry/dimension checks, runtime material and bloom-group checks, and matched before/after portrait tooling. Catalogue IDs and growth/harvest contracts remain intact. Blender source checks, all 60 native and Compatibility portraits, and the full gameplay smoke suite pass.

**Plain:** Every catalogue plant has a more detailed model and textured surfaces, with comparison images showing its old and new appearance.

**Why:** Makes plants more natural to inspect and photograph while retaining their familiar planting and gardening behaviour.

### [2026-09-27 11:08] Changed

**Tech:** `art_source/mountain_forms.py`, `build_environment.py`, `shaders/mountain.gdshader` — detailed alpine terrain and materials around the whole garden.

**Dev:** Rebuilt the basin with asymmetric massifs, erosion grooves and rock spurs on a 448-cell grid, plus three overlapping outer ridge chains. Added world-aligned rock normal detail, mineral strata, scree, slope/altitude vegetation transitions and high-elevation snow. Woodland now follows gentler slopes and an irregular treeline with better-proportioned tree crowns. Preserved lake level and playable garden geometry; reduced the exported environment from about 98 MiB to 58 MiB. Added terrain/shoreline/budget validation and four-direction rendering previews; verified Blender sources, both Forward+ and Compatibility rendering, and the full gameplay smoke suite.

**Plain:** The mountains surrounding the garden have more varied peaks, rocky faces, snowy summits and natural woodland patterns.

**Why:** Gives every background view greater depth and believable landscape detail while keeping the garden playable and the environment asset smaller.

### [2026-09-27 10:29] Changed

**Tech:** `art_source/build_shop.py`, `build_companions.py`, `build_wildlife.py`, `scripts/garden_art.gd` — detailed Blender models and embedded PBR materials used directly in the game.

**Dev:** Rebuilt all 11 shop structures and 13 animal models/variants with bevelled joinery, formed stone/clay surfaces, glazing, continuous companion body surfaces, articulated wings, feathers, fins and coat markings. Added deterministic colour/normal/roughness textures, packed editable Blender libraries, compressed Godot texture imports and shared model caching. Preserved sign labels, lantern lights, animal pivots, placement dimensions and existing save/behaviour contracts. Inspection exports now preserve Blender GLBs. Extended asset, pivot and greenhouse geometry validation; gameplay smoke tests pass.

**Plain:** Every shop structure and animal has a more detailed model, with textured materials and finer visible features throughout the garden.

**Why:** Makes close-up gardening, wildlife encounters and garden photography feel richer and more natural while preserving the game's interactions.

### [2026-09-26 08:28] Added

**Tech:** `bath_life.gd`, `soundscape.gd`, `mountain.gdshader`, `assets/shop/` — bathing birds, regional ambience and inspectable shop models.

**Dev:** Added daylight landing/bathing cycles, splash droplets and distance-faded calls; crossfaded four music themes with waterside/woodland ambience. Completed greenhouse intermediate posts, raised the distant snow line, varied rock and vegetation shading, reduced excessive mist washout, and exported Godot/GLB shop inspection copies. Audio seam and gameplay tests cover the additions.

**Plain:** Birds play in bird baths, each garden area has a different soundscape, and the greenhouse and distant hills look more natural.

**Why:** Adds life and variety while fixing floating supports and pale scenery and making the shop models accessible for inspection.

### [2026-09-26 08:13] Fixed

**Tech:** `garden.gd/fulfill_order`, `load_game`, `catalogue.gd` — saved order IDs, menu labels, and shop additions.

**Dev:** Canonicalized saved inventory/order lookup IDs, added a real JSON-roundtrip delivery regression, halved next-morning transition speed, replaced unsupported menu glyphs with text, clarified Remove, and added a 3-petal limestone stone. Documented shop functions and added an unlisted testing entry.

**Plain:** Saved basket items work for orders, menu prices are readable, and the shop includes a small stone.

**Why:** Fixes blocked deliveries and clarifies the garden tools and purchases.

### [2026-09-26 07:47] Changed

**Tech:** `garden.gd/collect_plant`, `garden_care.gd/collect_wild`, `garden_visitors.gd` — shared collection and visible order inventory.

**Dev:** Disabled kangaroo visits, shared mature-plant yields between pruning and gathering, persisted daily border collection, surfaced baskets in Shop and Orders, disabled incomplete deliveries, and reserved active-order stock when selling surplus. Added order lifecycle, duplicate reward, collection and save regressions.

**Plain:** Pruning now collects items for orders, your basket is easy to find, and only rabbits visit for now.

**Why:** Makes collecting and fulfilling requests clear and prevents accidental sale of requested items.

### [2026-09-23 18:54] Added

**Tech:** `scripts/garden_care.gd`, `scripts/garden_visitors.gd`, `scripts/garden.gd` — outdoor care, animal visits, shop hives and arrow navigation.

**Dev:** Added persistent three-cut outdoor pruning with safe bed pruning, visible rake furrows and upgrade widening with footprint checks, temporary rabbit/kangaroo groups including a joey, and saved hive ornaments with daytime bees. Clarified seed unlock costs and seasonal growth; tomatoes remain plantable year-round. Added gameplay regressions for these features and arrow input.

**Plain:** Clear overgrown paths, rake visible trails, welcome rabbits and kangaroos, place a beehive, and walk using the arrow keys.

**Why:** Makes garden care understandable and useful while adding more life and flexible controls.

### [2026-09-21 13:37] Fixed

**Tech:** `web/shell.html`, `web/viewport.js` — visible-viewport layout and optional fullscreen.

**Dev:** Removed the canvas from document flow, replaced the centred grid launch overlay with a scrollable flex layout, and size both against VisualViewport with resize/orientation handling and safe-area insets. Added a user-initiated fullscreen button with a non-blocking fallback while retaining the existing CSP.

**Plain:** The welcome screen and game fill the available iPad browser area, with the play button reachable and fullscreen available on supported browsers.

**Why:** Lets tablet players reach and play the game instead of seeing a clipped welcome screen below a blank area.

### [2026-09-21 08:47] Added

**Tech:** `scripts/touch_controls.gd`, `scripts/garden.gd/gameplay_active` — adaptive touch controls and mobile layouts.

**Dev:** Added capability-based detection without JavaScript eval, tracked multi-touch gestures, analogue walking, centre aiming, repeated care actions, placement controls, lift undo, responsive menus, touch onboarding, virtual keyboard support, browser photo downloads and saved control/display preferences. Mobile graphics reduce resolution, shadows and distant detail; focus loss clears gestures and saves progress. Desktop gameplay no longer depends on touch requiring pointer lock.

**Plain:** Phones and tablets can play with a thumbstick, drag-to-look, large tool buttons and menus made for touch.

**Why:** Makes the same garden accessible without a keyboard or mouse while preserving desktop controls and browser security protections.

### [2026-09-21 08:12] Added

**Tech:** `scripts/garden_art.gd/sign_board`, `scripts/garden.gd/sign_editor_page` — correctly oriented garden labels and custom signs.

**Dev:** Replaced labels behind boards with outward-facing, single-sided text on both faces; added a 64-character plain-text editor, opaque colour picker, placement previews, free edits, and backward-compatible saved sign text and colour. Signs use existing rotation, move and remove tools.

**Plain:** Garden signs read correctly, and you can place your own signs with personal messages and text colours.

**Why:** Makes the garden easier to navigate and gives players another way to make it their own.

### [2026-09-21 08:01] Added

**Tech:** `scripts/experience.gd/settings_page`, `scripts/garden.gd/apply_mouse_look` — independent horizontal and vertical mouse inversion.

**Dev:** Grouped inversion switches under Mouse Look, added a saved `invert_x` preference, and retained the existing `invert_y` key so older saves preserve their vertical setting; both axes apply to walking and photo-mode look.

**Plain:** You can now reverse left/right and up/down mouse movement separately in Settings.

**Why:** Makes camera controls easier to find and adapt to your preferred way of looking around.
