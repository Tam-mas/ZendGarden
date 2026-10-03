# Changelog

### [2026-10-03 12:22] Fixed

**Tech:** `web/save-format.js/validateSave` — accept saved watered-ground patch records.

**Dev:** Match `GardenTools.water_ground` by validating each patch's finite `x`, `z`, `radius` and `until` fields instead of treating watered ground as scalar terrain offsets. Preserve save bytes and migration archives without conversion, including expired patches. The deployed validator reproduced the reported startup message with a valid watered save; validation fails before Godot starts or autosaves. Cover v1/v2 encrypted copies, migrated-save reloads, later progress, malformed-patch rejection and unchanged databases in Chrome and WebKit. Verify watered saves in the existing exported Godot runtime and retained bytes on mount failure; record player Update 15 and check update dismissal, the browser loader, package and security checks.

**Plain:** Saved gardens with watered ground can open again after a refresh or a move to the new address.

**Why:** Restores access to affected gardens while preserving their progress and recovery copies.

### [2026-10-03 11:07] Added

**Tech:** `GardenLeisure`, `GardenCompanion`, `GardenTouch`, `garden.gd` — furniture viewpoints and companion invitations.

**Dev:** Add nearby facing interactions for benches, pergolas and ponds, respecting structure rotation. Resting exposes clickable companion invitations on desktop, right-drag look and safe exits through movement, tools or removed furniture; saves retain the pre-rest ground position. Add path-following call/settle commands, petting animation, sunny cat stretches and dog sniffing, using existing articulated models. Mirror actions in touch Interact and Garden controls, document controls and record Update 14. Validate real navigation, rotated furniture, pond camera direction, reach, save position, pet animations and touch commands in native and Compatibility renderers. The full project suite passes, and the local browser export passes package and security checks.

**Plain:** Garden furniture now offers places to pause, with companions you can call, pet and invite to share the view.

**Why:** Gives players more ways to enjoy and inhabit the garden they have made.

### [2026-10-03 11:00] Added

**Tech:** `GardenTutorial`, `GardenExperience`, `garden.gd` — interactive welcome walk.

**Dev:** Replace the initial five-page welcome with an optional five-action garden lesson. Persist progress and the planted flower in an optional schema-2 field, handle removed lesson plants, and grant only that flower a first-morning bloom. Add a separate one-flower welcome request without replacing ordinary orders; prevent its replenishment. Add first-use terrain, layer and dormancy hints. Verify real tool actions, delivery accounting, saved progress, skipping, replay, actual touch buttons and desktop/phone card bounds without covering aiming or movement. Confirm in isolated Chrome profiles that both legacy saves load and a saved welcome lesson resumes through keyboard input and persists its next morning. Record Update 13.

**Plain:** New gardeners can learn by growing and sharing their first flower, with the option to skip or resume later.

**Why:** Makes the first garden experience easier to learn without remembering pages of instructions.

### [2026-10-03 09:59] Changed

**Tech:** `GardenTheme`, `GardenInterface`, `GardenSeedCollection`, `garden.gd/make_ui`, `GardenTouch`, `GardenUpdates` — original brown frames and a compact sidebar.

**Dev:** Restore the existing wood/button textures, decorative borders and serif font family across menus, HUD panels, touch readouts and update history. Use a 300-pixel desktop sidebar instead of the previous 350–420-pixel range, with three-column categories, smaller reflowing desktop cards, constrained buttons and shorter shop labels. Retain search, filters, favourites, recent planting, shop previews, care inspection and structure selection. Remove background styles from shortcut instructions and the compact desktop readout, retaining only text shadows. Preserve responsive positioning and save fields; record player Update 12 and verify menu width across Seeds, Shop, Orders, Settings and Guide on desktop/phone layouts, plus browsing, touch gestures and saved update dismissal.

**Plain:** The familiar warm brown frames return with a slimmer sidebar and unobtrusive shortcut text.

**Why:** Restores the garden’s visual character and leaves more of the landscape visible while browsing.

### [2026-10-03 09:40] Added

**Tech:** `GardenStructureTarget`, `garden.gd/update_hover`, `perform_action`, `GardenTouch.act` — surface targeting and removal tint for placed structures.

**Dev:** Cache two-sided mesh-derived picking shapes on a dedicated query-only collision layer, following rotated structures without changing walking collision. The Remove tool selects the closest visible surface within reach and before terrain, tints its materials warm red without changing shared resources, and displays the structure name and full refund. Use the same node target for dispatch and touch Undo, clear selection after removal or tool changes, and retain existing structure save and refund semantics. Cover all eleven structure types, overlapping plants, material restoration, reach, terrain occlusion, saved removal and restoration of custom signs and stocked ponds. Update the old synthetic stone-removal check to supply the selected object; settle viewport changes and pause world updates during injected touch tests. Add player Update 11.

**Plain:** Point the Remove tool at a garden structure to see it turn red before packing it away.

**Why:** Makes it clear which structure will be removed, even when aiming at its roof or a rotated part.

### [2026-10-03 09:21] Changed

**Tech:** `GardenTheme`, `GardenInterface`, `GardenSeedCollection`, `GardenTouch` — readable menu surfaces, typography and display-aware layout.

**Dev:** Use the engine's bundled body font, larger text, opaque green surfaces, light portrait backdrops and persistent gold selected-state borders. Replace the fixed desktop UI scale with logical display pixels and position menus, tools, crosshair and readouts from the available viewport. Reflow card heights around wrapped captions, collapse categories on short screens, constrain dropdown widths, and remove duplicated seed-card detail from the sidebar. Verify desktop/phone menu bounds, caption containment, control-mode switching, desktop targeting and existing touch gestures; add Update 10 and update the player guide.

**Plain:** Clearer text and calmer backgrounds make the garden menus easier to read on computers and phones.

**Why:** Keeps controls legible while giving plant choices and the garden view more room.

### [2026-10-03 09:20] Fixed

**Tech:** `plant_shape.gdshaderinc`, `GardenPlantGrowth.set_shape`, `GardenPlantInspector`, `garden.gd/ghost_material` — bounded plant variation on Compatibility/WebGL.

**Dev:** A full-world Compatibility render exposed exhaustion of the global instance-uniform buffer that isolated plant checks did not exercise. Compile ordinary shape uniforms for that renderer, give planted specimens private material values only when needed, reuse each specimen's owned materials when its shape changes, and retain shared identity values for decorative plants. Keep Forward+ instance uniforms and carry the same deformation into previews and outlines. Verify independent, repeatable plant shape, the full scene and its 142-plant dense bed. Use deferred node disposal in rendered tests, matching the game's lifecycle. Add rendered Compatibility checks to the regular suite and make the actual browser test reject native renderer errors as well as script failures.

**Plain:** Plant variation remains reliable in browser gardens with many plants.

**Why:** Prevents hardware shader limits from interrupting rendering as the garden fills out.

### [2026-10-03 08:51] Added

**Tech:** `GardenPlantInspector`, `garden.gd/aimed_plant`, `GardenTouch` — plant care inspector and consistent action target.

**Dev:** Outline the aimed plant and explain its growth stage, watering, season, greenhouse protection, shade source, stress and temporary watering boost using the same conditions as growth. Restore shared materials when the target changes and cache outline/preview variants through renderer cleanup. Use the displayed target for move/remove and touch undo, and expose layer switching while inspecting on phones. Cover overlapping plants, actual move actions, preview removal and responsive desktop/phone views.

**Plain:** Point at a plant to see how it is growing, what it needs and which plant your tool will reach.

**Why:** Makes crowded gardens easier to tend and explains why a plant may be growing slowly.

### [2026-10-03 08:51] Added

**Tech:** `GardenSeedCollection`, `assets/ui/shop`, `garden.gd/save_game` — searchable seed collection, filters and saved favourites.

**Dev:** Search all 106 species without rebuilding the input field, filter by growing season, light, authored mature height, colour and wildlife, and sort by name, height or growth time. Save favourites and the last twenty actual planting choices as optional version-2 save fields. Add ornament portraits rendered from the existing GLBs, touch-sized card controls, result counts and empty-state guidance. Verify filtering, persistent selection lists and real desktop/phone menus.

**Plain:** Find plants more easily, keep favourite seeds close and preview decorations before placing them.

**Why:** Reduces browsing time as the seed collection grows.

### [2026-10-03 08:51] Added

**Tech:** `build_plant_growth.py`, `GardenPlantGrowth`, `plant_shape.gdshaderinc` — supplementary growth models and persistent plant shape.

**Dev:** Generate separate Seedling, Juvenile and Buds meshes for all 106 species in a new editable Blender library without rewriting the mature source libraries. Export embedded PBR maps with compressed imports; added geometry totals 572,200 triangles under a 650,000 budget. Switch organs through development, flowering or ripening while preserving existing height/pruning behavior. Apply coherent instance bending/twist to foliage, blooms, previews and outlines. Persist shape seed and orientation in version-2 saves, with deterministic defaults for old gardens; add asset, stage, save and read-only Blender source checks. Record player-facing Updates 7–9 without renumbering prior releases.

**Plain:** Plants grow from small seedlings through young leaves and buds, with subtle differences in each planting.

**Why:** Makes growth easier to see and garden arrangements feel more natural.

### [2026-10-01 13:40] Changed

**Tech:** `wrangler.jsonc`, `functions/_middleware.js`, `web/_routes.json` — activate and verify the production garden move.

**Dev:** Create private R2 transfer storage with one-day abandoned-object cleanup, bind production only, and keep previews disabled. Deploy and verify the ordinary game with migration off before enabling it. Handle Pages' extensionless HTML routing without losing the moving page's cross-domain policy, with disabled-reader routes returning to the original game. Add an opt-in live Chrome check using isolated fixture saves; verify real R2 transfers, automatic navigation, exact-byte import, Godot startup, unchanged original storage, recovery access and retained latest progress on repeat visits. Record rollout/rollback deployments and ignore Wrangler's local cache.

**Plain:** Visiting the old address now gently carries your garden to zend.garden while keeping its original copy safe.

**Why:** Makes the move work on the real hosting setup, with a tested way to keep gardening if a transfer fails.

### [2026-10-01 13:30] Fixed

**Tech:** `garden.gd/browser_save_result`, `tests/migration_game.cjs` — browser save verification respects the production security policy.

**Dev:** Replace JavaScript evaluation with direct JavaScriptBridge object calls for save-ready/failure notifications. A deployed Chrome check exposed the blocked callback before production activation; run actual exported runtime tests with CSP applied, covering both save versions and failed IndexedDB mounting without overwriting the saved bytes.

**Plain:** The garden can finish its safety checks and open correctly under the live site's browser protections.

**Why:** Keeps the protective save check compatible with the real deployment without relaxing browser security.

### [2026-10-01 11:43] Added

**Tech:** `web/migration*`, `functions/api/garden-transfer/[action].js`, `garden.gd/browser_save_check` — protected domain migration with player-facing moving and arrival notes.

**Dev:** Add a read-only old-origin save reader, encrypted fifteen-minute transfer relay, separate immutable local recovery copies, staged and verified atomic promotion, explicit conflict choices, repeat-import receipts and game-session locks. Verify Godot’s mounted save before world creation to block blank-save autosave after an import/mount failure. Add an off switch and stay route, preserve save schema versions, increment player history to Update 6, and document private R2 binding/lifecycle, deployment and rollback. Test relay/encryption contracts, Chrome/WebKit failure paths with unchanged source bytes, actual exported Godot startup and failed storage mounting, and packaged site policy. Live activation remains off pending account resource setup and production verification.

**Plain:** Returning players can gently move their garden to its new cozy home, with the original copy kept safe and a choice if another garden already lives there.

**Why:** Makes the new address easy to adopt while keeping failed moves and rollbacks recoverable.

### [2026-10-01 08:11] Added

**Tech:** `GardenUpdates`, `GardenExperience.settings_page`, `settings.updates_seen` — dismissible player history and update counter.

**Dev:** Add a quiet responsive What’s new dialog with curated, non-technical entries for visible changes. Returning players see unseen entries once; dismissal persists in the existing garden settings, and Settings can reopen the full history. New visitors continue onboarding without historical update interruptions. Derive the displayed version from the newest numbered entry, document future increments in AGENTS.md, and cover dismissal/reload, reopening, keyboard input and desktop/phone layouts.

**Plain:** Players can see how the garden is evolving, close the update notes, and find them again in Settings.

**Why:** Makes meaningful improvements easy to discover without repeatedly interrupting play.

### [2026-10-01 08:11] Fixed

**Tech:** `build_shop.py/greenhouse`, `shop_library.blend`, `assets/shop/greenhouse.glb` — roof glazing orientation.

**Dev:** Align each roof pane’s width with the ridge and its long axis with the slope using an explicit orthonormal basis. Rebuild only the greenhouse using its existing suffixed source root and materials, retaining the other gallery assets and avoiding interactive scene changes. Verify all eight exported pane bays and roof-plane alignment, reproduce the failure against the previous GLB, render matched before/after views, and check packed source images.

**Plain:** The greenhouse glass now sits correctly along both sides of the roof.

**Why:** Removes the misplaced glass sheets sticking across the greenhouse roof.

### [2026-10-01 08:11] Fixed

**Tech:** `Soundscape.music_volume`, `default_bus_layout.tres/Music`, `GardenExperience` — exact music mute at zero.

**Dev:** Route all four music loops through a dedicated Music bus, mute that bus immediately at zero, and set each music player’s linear output to exact zero instead of fading toward the former -80 dB floor. Keep loop timelines running and nature outside the music bus. Restore music when the slider rises, and cover immediate mute/unmute, routing, continued playback and saved settings through both focused and actual settings-slider tests.

**Plain:** Moving Music volume all the way down completely silences the music while preserving nature sounds.

**Why:** Lets players choose a fully music-free garden without residual notes or a waiting period.

### [2026-10-01 07:44] Changed

**Tech:** `tools/build_audio.py`, `Soundscape.update_location`, `tests/check_audio.py`, `tests/soundscape.gd` — compatible area themes and calmer ambience.

**Dev:** Replace the transposed piano-like motifs and fixed C/G drone with four separately phrased felt-key, soft-pluck, low-flute and sustained-tone themes sharing a concert-tuned D/E/G/A/B palette. Render exact 64-second music phrases with wrapped note/reverb tails and 32-second circular nature loops; soften night insects and bird calls and remove the pitched water layer. Extend music fades, stabilize area boundaries, map later orchards/woodland by setting, and soften music at night/in rain while retaining independent volume settings. Add PCM pitch/level/loop checks and runtime coverage for theme selection, fades, playback pitch and mutes; document the musical direction and listening limits.

**Plain:** Each part of the garden now has its own quieter, more spacious tune, with smoother changes between areas and softer nature sounds.

**Why:** Removes distracting harmonic clashes and repetition so the garden feels more restful.

### [2026-09-28 21:08] Fixed

**Tech:** `GardenTouch._input`, `layout`, `layout_context` — independent touch aiming and responsive mobile HUD.

**Dev:** Derive looking movement from consecutive positions belonging to the same finger ID, avoiding the web backend's cross-finger relative deltas. Preserve concurrent movement/action ownership, consume duplicate synthesized gameplay mouse events, and clear contacts on cancellation, focus loss and resize. Add fixed top status/Seeds/Garden controls, bottom thumb controls, a readable tool card, contextual actions and two-column tool menus; preserve left-handed and size settings. Cover alternating finger IDs, incorrect relative deltas, release/cancel/reuse and HUD bounds/overlaps at seven viewport sizes, three control sizes and both handedness options.

**Plain:** Walking and looking together no longer makes the camera jump, and phones and tablets have clearer, consistently placed controls.

**Why:** Makes the garden easier to navigate and tend with two thumbs.

### [2026-09-27 18:42] Fixed

**Tech:** `garden.gd/update_placement_preview`, `ghost_material`, `leaf_preview.gdshader` — faithful botanical placement previews.

**Dev:** Preserve surface textures, normal maps, sidedness and leaf wind in tinted preview materials without mutating shared plant resources. Reuse preview yaw when planting, mirror current scale/rotation/bloom state when moving, distinguish individual move targets, and apply blocked-placement tint immediately on preview creation. Add a regression check for all 106 models and preview state transitions to the test runner. New planting previews continue to show the mature form while seedlings grow into it.

**Plain:** Plant previews keep their detailed shapes and orientation, and moving a plant shows its current size and flowers.

**Why:** Makes it easier to judge how a plant will look and fit before placing it.

### [2026-09-27 18:25] Changed

**Tech:** `.github/workflows/web-build.yml` — refresh the GitHub Actions build dependencies.

**Dev:** Update checkout to 7.0.1, setup-python to 7.0.0 and upload-artifact to 7.0.1 through the pending Dependabot pull requests. Keep immutable commit pins, read-only repository permissions, disabled credential persistence and the existing build configuration.

**Plain:** The automated tools used to build and package the browser game are up to date.

**Why:** Keeps the release process compatible with supported build tooling and its fixes.

### [2026-09-27 18:20] Removed

**Tech:** `scripts/garden.gd/make_world`, `animate_garden` — randomized ambient sphere meshes.

**Dev:** Removed the 35 randomly placed pale gold spheres and their idle motion so they no longer appear as floating dots in the sky or around the garden.

**Plain:** Removed the stray floating circles from the garden.

**Why:** Keeps the view clear of unexplained objects while looking around the garden.

### [2026-09-27 16:03] Changed

**Tech:** `web/shell.html`, `web/art/garden-woodland.jpg` — current in-game welcome-page background.

**Dev:** Replace the outdated lakeside backdrop with the current garden capture used in the README, showing the detailed planting and expanded mountain woodland. Encode the screenshot as a compact JPEG and use a new asset filename so returning browsers request the updated image.

**Plain:** The website's welcome screen now shows the garden as it looks today.

**Why:** Gives new players an accurate first impression of the updated game.

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
