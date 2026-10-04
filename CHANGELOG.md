### [2026-10-04 16:58] Performance

**Tech:** `GardenPlantBatches`, `GardenPlantIndex`, `GardenPlantGrowth`, `GardenTouch` — dense-garden rendering and care

**Dev:** Profile a disposable copy of the supplied day-77 save containing 1,739 plants and 55 structures. Batch visible organs and border planting in 6 m cells, send saved shape variation through MultiMesh custom data, and retain individually outlined selections without duplicate renders. Update only affected transforms for trims within a growth stage; rebuild on stage or placement changes. Index nearby targeting, layered overlap and canopy shade; calculate growth conditions once per morning, reuse seed-marker meshes only when needed, and restore saved scales without startup tweens. Auto graphics uses 85% resolution when no explicit resolution is selected, lighter antialiasing (FXAA where supported), earlier distant LOD and shorter small-plant shadow ranges; Standard restores full detail, while Mobile keeps its existing settings. Direct Chrome comparison against main shows median frame times of 56.6 → 35.6 ms near the pergola and 158.6 → 49.0 ms across the dense terrace, with draw calls reduced by approximately 70–83%. Add reusable isolated benchmarks, real-renderer interaction/settings checks and player release 36; preserve save schema and dismissal state.

**Plain:** Fuller gardens are smoother to explore and tend, with automatic graphics keeping detail closest to the player.

**Why:** Repeated plants should not make a large, well-loved garden unnecessarily slow to enjoy.

### [2026-10-04 16:57] Fixed

**Tech:** `GardenClimbingSupport`, `build_climbing_details.py` — realistic support growth in place of oversized climber ovals

**Dev:** Identify the screenshot's lilac rows as generic climbing-support spheres, including Clematis around the saved pergola. Replace them with small curved Sweet pea/Clematis blossoms, appropriate pea/cucumber/jasmine flowers, compound leaves and a continuous thin stem following the authored post coordinates for rotated arbors, pergolas, trellises and gazebos. Keep support growth in world coordinates so specimen rotation and height variation cannot skew it; update on care, rearrangement and terrain events, respecting growth/bloom stages. Group support organs and share existing botanical surface maps rather than embed duplicated textures. Preserve the open Blender project by building six small organ GLBs in an approved background process. Add player release 35 and botanical/profile documentation.

**Plain:** Climbing flowers now follow their supports naturally instead of growing oversized rows of pink ovals.

**Why:** Recognisable flowers and grounded stems make the planting easier to enjoy up close.

### [2026-10-04 14:52] Added

**Tech:** `art_source/animal_studies/wombat`, `build_animals.py`, `preview/preview.gd` — supplied wombat sculpt coat, rig and motion study

**Dev:** Import the supplied roughly two-million-triangle STL through Blender MCP, preserving the original and a dense hidden source reference. Close thin printed-fur folds with a continuous voxel surface, retain paws/claws during relaxation, fit small eyes and export a 62,356-triangle study with packed WebP maps and a 21-bone rig. Generate coarse fur colour detail and convert all new maps to WebP, saving 47.1% versus their PNG equivalents with lossless normal/alpha checks. Bake idle, slow four-beat walk, forage, look and standing rest; correct uneven sole contacts and keep ear weights off the tall back. Extend the isolated comparison with a frozen main wombat baseline, per-animal capture reports and actual rendered GIFs. Verify all clip loops, weights, anatomical ear bounds and supporting paws approximately 1 mm above the floor; render all actions in Godot Compatibility and Forward+. Refresh the MCP review scene while preserving the existing interactive project and selection. Keep the production wombat, model selections, saves and player release history unchanged.

**Plain:** The supplied wombat now has a detailed coat and gentle movement, with a viewer to compare it beside the garden's current wombat.

**Why:** A stronger sculpt and restrained, grounded movements make the next animal model easier to judge before adding it to the garden.

### [2026-10-04 13:56] Changed

**Tech:** `GardenArt`, `GardenAnimalMotion`, `GardenCompanion`, `GardenVisitors`, `animal_studies/promote.py` — approved supplied-sculpt production animals

**Dev:** Replace cat, dog, fox, echidna and rabbit production GLBs with the approved STL-based models. Preserve rig facing wrappers, per-instance animation resources and navigation roots; map visitor alert/forage states, match walk speed to stance timing and integrate rabbit travel during flight. Add grounded companion pet/settle actions and a cat stretch without changing approved anatomy or coats. Embed all five models' maps as WebP, preserving lossless normals and alpha; retain packed editable game sources, canonical exports and frozen main review baselines. Record the new selections and protect them during older library rebuilds. Add production rig/clip/contact checks and extend source verification. Add player release 34; existing saves and dismissal state stay compatible.

**Plain:** The approved detailed cat, dog, fox, echidna and rabbit now appear in the garden with their coats, natural movement and familiar interactions.

**Why:** Better animal shapes and species-specific detail make companions and quiet visitors more enjoyable to watch.

### [2026-10-04 12:31] Added

**Tech:** `art_source/animal_studies` — supplied fox, dog, echidna and rabbit sculpt texture/animation prototypes

**Dev:** Import each roughly two-million-triangle STL through Blender MCP without changing the active authoring scene, preserve dense references in packed sources, and export 56–67k-triangle weighted prototypes. Fit asymmetric eye sockets, add species coats, short laid fur and distinct baked walk/hop/forage/look actions. Use a padded echidna spine atlas to avoid UV/ray-bake seams. Convert every new map and embedded GLB image to WebP, saving 63.2% versus the corresponding PNGs with lossless normal/alpha checks. Extend the isolated cat comparison to five species, measure posed heights and retain fixed baseline joint tracks so runtime GLTF loading does not distort the old fox. Verify packed maps, weights, finite/looped motions, sampled floor contact and actual Godot rendered motion. Keep production models, saved selections, player history and live exports unchanged; further retopology, download optimisation and interaction/navigation integration remain production work.

**Plain:** Four supplied animal models now have distinct coats and movement, with a separate viewer to compare them with the garden animals.

**Why:** Better anatomical starting shapes and species-specific detail make the next animal design choices easier to review.

### [2026-10-04 11:26] Added

**Tech:** `art_source/cat_study` — isolated supplied-STL cat texture, skinning and motion experiment

**Dev:** Preserve the supplied two-million-triangle sculpt as a hidden Blender reference and create a 57k-triangle GLB with baked anatomical tabby pigment/normal maps, inset eyes and blinking lids, weighted short fur and fine whiskers. Bake a 24-bone rig's planted-contact IK into idle/look/walk clips; classify asymmetrical paw weights using measured centres. Add a standalone Godot comparison with the retained production cat and its existing rigid motions, plus packed-map, weight, loop and contact validation. Keep production assets, model choices, saves and player release history unchanged; the prototype still needs sculpt/retopology cleanup and companion interaction clips before integration.

**Plain:** A separate animated, textured cat prototype lets us compare the supplied model with the cat currently in the garden.

**Why:** A better anatomical starting point can produce more convincing animals while keeping the existing garden safe to review against.

### [2026-10-04 10:12] Added

**Tech:** `GardenSaveFiles`, `GardenSaveFormat`, `GardenExperience.settings_page`, `web/save-files.js` — portable garden JSON download and upload

**Dev:** Add Settings controls for current-save export, confirmed import and recovery-copy export on desktop and web. Validate v1/v2 file shapes, catalogue references and size before touching the active save; preserve raw bytes and unknown fields. Save current progress, atomically write a previous-garden backup, then atomically install the selected copy and rebuild the scene. Check writes and report failures. The browser uses an external file-picker bridge under the existing CSP; verify the IndexedDB mount once per engine session so legitimate scene reloads retain imported progress. Avoid briefly requesting pointer capture while Escape opens Settings, which can lock the cursor over the menu in the browser. Return to Settings after importing; only request browser pointer capture during an active player gesture. Add save/recovery, responsive confirmation and browser file-flow checks.

**Plain:** Keep a downloadable garden copy and upload it to continue on another device, with a backup of the garden you replace.

**Why:** Players can protect their progress and move their garden between devices or browsers.

### [2026-10-03 21:46] Performance

**Tech:** `export_presets.cfg`, `GardenArt.save_card`, `tools/prepare_bed_textures.py` — compact runtime image encodings and source-map export exclusions

**Dev:** Convert 169 plant/ornament portraits and six landscape textures to WebP where smaller, verifying exact pixels and transparency for lossless conversions. Keep rebuild pigments in source folders while excluding separately imported copies of GLB-embedded maps. New opaque grass pigments use JPEG inside glTF, preserving normal/roughness maps; ground textures have mipmaps and the welcome photograph uses high-quality lossy compression. Browser export and source-library checks cover the resulting resources. The packaged site decreased from 667,383,235 to 663,674,270 bytes (3.54 MiB) despite the new plants and finishes; native/Compatibility, save and loader checks pass.

**Plain:** Garden images take less space while retaining their detail and transparent edges.

**Why:** Smaller downloads make entering the garden easier as its plant collection grows.

### [2026-10-03 21:45] Added

**Tech:** `GardenBedSurfaces`, `ground_detail.gdshader` — reusable whole-bed surface finishes

**Dev:** Add soil, desert sand, Japanese gravel, pine bark mulch, slate chips, warm pebbles and dark compost to the Shop with previews and an unlocked-bed selector. A paid finish is owned permanently and can be reused or replaced freely. Copy actual sculpted soil triangles rather than changing collision, plants, capacity or care rules. Persist purchases and bed choices in compatible schema-2 saves, default missing fields to soil, and reject unknown/locked-bed records. Store the four generated material originals and exact built-in ImageGen prompts for rebuilds.

**Plain:** Choose sand, stone, bark or earth for an entire bed without disturbing its plants.

**Why:** Desert, woodland and Japanese-style gardens can each have an appropriate ground finish.

### [2026-10-03 21:44] Added

**Tech:** `build_low_grasses.py`, `GardenCatalogue` — twelve low-growing plants, IDs 136–147

**Dev:** Build distinct creeping and clumping models with early growth stages through Blender MCP in an isolated library, preserving the active Blender scene. Add dwarf/black mondo, velvet zoysia, buffalo grass, creeping bentgrass/red fescue, sheep's/bearskin fescue, blue moor grass, Evergold/Snowline sedges and dwarf golden sweet flag. Preserve earlier IDs and saves; add searchable botanical names, model-rendered portraits and independent geometry/stature budgets.

**Plain:** Twelve short and creeping plants bring softer edges and low carpets to the garden.

**Why:** More choices at ground level make small gardens and layered plantings easier to design.

### [2026-10-03 21:43] Fixed

**Tech:** `GardenWildlifeMotion`, `refresh_wildlife` — visitor-pair spacing and independent animation phases

**Dev:** Normal gameplay intentionally spawns native-bird and lorikeet pairs. Lorikeets previously shared arrival timing and almost identical routes. Assign species-specific pair slots, separate perches (including bird-bath rim positions), offset approaches and arrivals, and start animation clips at distinct phases. Verify a full 56-second visitor cycle for overlap and asynchronous wingbeats through the normal dispatcher.

**Plain:** Visiting birds have room to fly and rest beside each other with more natural timing.

**Why:** Bird pairs no longer look like synchronised copies.

### [2026-10-03 21:42] Changed

**Tech:** `web/shell.html`, `GardenExperience.welcome` — supplied garden photograph behind start screens

**Dev:** Replace the browser's woodland backdrop with the supplied Bk.jpg composition, using full-resolution WebP in the browser shell/migration page and in-game welcome. Preserve existing timber framing and controls. Update exported-site checks to require the new image.

**Plain:** A richly planted garden view welcomes players at the start screen.

**Why:** The introduction now reflects the user's chosen garden image.

# Changelog

### [2026-10-03 20:26] Changed

**Tech:** `art_source/overhaul/model_choices.json`, `selection_policy.py`, `tools/model_comparison/apply.py` — apply the completed model review

**Dev:** Install the exact main ca52914 cat, dog, bee, frog and rabbit GLBs, retain the other 50 frozen candidates, and archive the five selected originals with their hashes. Individual Blender exports preserve these runtime choices while keeping new source anatomy editable. Restore procedural bee wingbeats, grounded frog hops and travelling/resting rabbit motion alongside the existing companion fallback. Keep strict byte checks for selected originals and skin/clip checks for upgraded animals; add movement regression coverage and player update 28. While its garden process loop is paused, the UI check explicitly repeats the live game's HUD updates to settle deferred text wrapping before checking geometry.

**Plain:** Keep the familiar cat, dog, bee, frog and rabbit while using the selected new versions of the other animals, structures and tools.

**Why:** Make the garden reflect the completed comparison and preserve those preferences through future model rebuilds.

### [2026-10-03 20:08] Added

**Tech:** `tools/model_comparison/`, `Compare Models.command` — temporary native model review viewer

**Dev:** Freeze 55 current GLBs and 33 counterparts from verified GitHub main ca52914, including extracted shed/cottage geometry and the original procedural footbridge. Show one pair with synchronized metre-scale cameras, lighting, authored clip playback and rest-pose restoration. Default to new, disable unavailable old variants, atomically save portable decisions and resume the review; snapshots remain ignored and outside web exports. Validate all variants/clips, rest transforms, navigation and persisted choices without replacing game assets or real review decisions.

**Plain:** Compare the previous and upgraded models side by side, choose which ones to keep and return to your saved review later.

**Why:** Let the final garden use the models you prefer before the overhaul is integrated.

### [2026-10-03 19:38] Fixed

**Tech:** `tests/soundscape.gd`, `tests/check_mountains.py` — verification cleanup and landscape resource-name checks

**Dev:** Explicitly released each test playback stream and cleared the player table before freeing the soundscape, allowing the mixer to retire its resources before shutdown. Checked both node and mesh-resource names for forest chunks after repeated Blender library appends; the export canonicalizer restores both without changing vertices.

**Plain:** Automatic checks now close their audio cleanly and catch renamed landscape resources earlier.

**Why:** Keep verification reliable while rebuilding and reviewing the garden's model libraries.

### [2026-10-03 18:29] Changed

**Tech:** `art_source/overhaul/skin_rig.py`, `realism.py`, `common_hq.py`, `tools.py` — connected weighted skins and library-wide material rollout

**Dev:** Added continuous remeshed skins and real armatures for eight mammals and six birds, baking existing NLA controls into bone clips without changing navigation ownership. Smoothed anatomical weights and attached fur cards to the same rig; used tapered sparse cutouts and underlying-surface normals to avoid flake-like tufts; retained rigid wings/wrists, gripping feet, facial details and existing clip names. Revised species proportions, coat lengths, short-haired feet, fine tabby scale and staggered wombat walking. Added bee/moth thorax fuzz and replaced wooden insect cuticle. Rolled generated cedar/limestone/plumage/coats across the library with physical-scale timber/mineral UVs, smaller micro-normal/roughness maps and an isolated five-tool material library preserving hand geometry. Preserved the glTF exporter’s matched bone rest/inverse-bind matrices, explicitly reset neutral poses and kept canonical landscape names on repeated exports. Tests require neutral bind agreement, skins, normalized weights, bone/control agreement, embedded alpha and existing budgets. Isolated each asset export from the gallery to avoid evaluating unrelated rigs. Editable galleries and actual exported/game-rendered previews document the resulting detailed stylised assets.

**Plain:** Animals bend more smoothly and have more distinct coats and plumage, while garden structures and tools gain finer wood, stone and metal detail.

**Why:** Improve close-up believability and movement throughout the non-plant model library.

### [2026-10-03 17:24] Changed

**Tech:** `art_source/overhaul/realism.py`, `GardenArt.soften_fur` — generated material assets and three realism prototypes

**Dev:** Preserved six built-in image-generation albedo/opacity sources and exact prompts; added Blender tinting, coat UVs, curved outward-facing short-fur cards and separate contour/flight-feather materials. Exported revised cat, kookaburra and bench prototypes through MCP, retaining animation clips and dimensions. Refined jaw, hind limbs, tail, bird skull/neck/bill and feather UVs. Godot shares alpha-hashed fur materials, uses softer diffuse lighting and avoids tiny fur self-shadows. Reduced micro-normal/roughness map sizes while preserving 1K colour detail. Added checks for PNG hair alpha, runtime fur shading and existing grounded animation. Documented the remaining species anatomy, skin deformation, grooming, texture and performance work explicitly; this is not a finished realism pass for all models.

**Plain:** The cat, kookaburra and bench have a first pass of finer coat, feather and wood details.

**Why:** Establish and verify a material workflow for more believable close-up garden models.

### [2026-10-03 16:29] Changed

**Tech:** `art_source/overhaul`, `GardenArt.detailed_model`, `GardenAnimalMotion`, `GardenWildlifeMotion` — MCP-authored model libraries and articulated wildlife playback

**Dev:** Rebuilt 21 placeable structures, 26 animals and three scenery assets in isolated Blender MCP scenes, retaining the landscape and saved furnishing identifiers. Added packed PBR maps, 103 animal clips, inverse-kinematics steps with ankle compensation, private animation-path normalization and manual playback without root-motion ownership. Appended ten shop furnishings, added twelve species with distinct visiting routines, integrated rest and insect-hotel interactions, and refreshed shop cards and inspection scenes. Source textures are excluded from game exports, and the environment shed is consolidated from 462 meshes to eight material batches. Expanded model, source, movement, direction and structure-removal validation; kept per-model triangle budgets below 65,000.

**Plain:** The garden has richer structures, more detailed animals and new visitors that move and behave in different ways.

**Why:** Make close-up gardening and quiet wildlife watching more visually pleasing while preserving existing gardens.

### [2026-10-03 14:37] Added

**Tech:** `art_source/concepts/wildlife-and-existing-structures-2026-10` — additional wildlife and faithful structure concept references.

**Dev:** Add twelve animal proposals with distinct movement, visit timing and player reactions, including three mammals, four named bird species and five insects. Generate seven labeled reference sheets with the built-in image tool; use current model renders and source geometry to retain the shapes of all eleven shop furnishings and five permanent scenery groups. Refine hoverfly antennae, preserve selected PNGs and current shape references, and record exact prompts and primary wildlife sources. Keep runtime assets, gameplay, saves and player update numbers unchanged in this concept-only pass.

**Plain:** Illustrated ideas add twelve possible animal visitors and show more detailed versions of the garden's existing structures.

**Why:** Provides a complete visual and behavior brief to review before the next model-building pass.

### [2026-10-03 14:13] Fixed

**Tech:** `tools/build_web.py/package_site`, `web/loader.js/loadChunk` — coherent browser downloads after updates.

**Dev:** Include each decoded pack piece's SHA-256 in its filename so different deployments never reuse a URL for different bytes. Revalidate the manifest and retry failed transfers or integrity checks once with a cache-reloading checksum-qualified request; continue checking both size and digest before starting Godot. Reproduce the exact previous error using a four-hour HTTP-cached old piece and a new manifest in isolated browsers; cover same-size stale bytes, truncated gzip and persistent corruption, and validate exported filenames. Preserve saves and migration and record player Update 22. Live headers showed a four-hour asset cache while the manifest revalidated, and a fresh isolated Chrome profile loaded the preceding production build.

**Plain:** The browser game keeps update files together and can recover automatically from an incomplete download.

**Why:** Lets returning players open the garden reliably after an update without clearing their saved garden.

### [2026-10-03 13:58] Added

**Tech:** `art_source/concepts/garden-expansion-2026-10` — structure and animal design references.

**Dev:** Create a new branch from published main and add six labeled concept sheets generated with the built-in image tool: a ten-structure overview, two detailed structure sheets, and three animal sheets covering all twelve wildlife models and both companions. Preserve text prompts and document proposed structure uses, current animal behaviour and the mother-with-joey variant. Explore new naturalistic designs from text briefs without replacing runtime assets. No player update number is added because this concept pass does not change gameplay.

**Plain:** New illustrated ideas show ten possible garden structures and fresh designs for all existing animals.

**Why:** Gives the next art pass a complete visual direction to review before building game models.

### [2026-10-03 13:33] Changed

**Tech:** `LICENSE`, `LICENSING.md`, `README.md` — custom free-play and source-sharing licence.

**Dev:** Replace the current first-party MIT offer with the Zend Garden Free Play and Share-Alike Licence 1.0 for future releases. Require no paid game access or gameplay unlocks, complete corresponding source for distributed/publicly hosted derivatives and the same terms for derivative code and assets. Permit voluntary donations without privileges, separate services and gameplay media; retain third-party licences, contributor copyrights and permissions granted with earlier MIT copies. Describe the project as source available, explicitly disclose that the custom wording has not had legal review, and document that historical MIT forks cannot be retroactively restricted. Publish a licence-only GitHub change without including pending gameplay or asset changes. No player update number is added because this does not change play.

**Plain:** Future versions and shared derivatives must stay free to play and share their editable source under the same rules.

**Why:** Expresses the creator's wish to keep the garden freely playable and its derivatives available for others to modify.

### [2026-10-03 13:04] Added

**Tech:** `GardenClearView, GardenInterface, GardenTouch` — HUD-free garden viewing.

**Dev:** Add Enjoy the view buttons to the desktop HUD, Guide and touch Garden drawer, with H shortcut. Hide UI layers, held tools, selection outlines, cursors and placement previews while time, weather and wildlife continue. Freeze walking, preserve the tool/menu/pointer state, and consume the first return key/click/tap, including synthetic touch mouse presses and the complete return finger gesture. Measure plain instruction text using its actual wrapped height so it stays above the toolbar on compact windows. Keep save schema and dismissal settings unchanged. Native/Compatibility control and responsive-layout checks, the gardening smoke test, read-only Blender source checks and browser package/security checks pass. In the exported Chrome game, H hides the overlays and G restores the held can and HUD without advancing the saved day.

**Plain:** Enjoy the garden with the interface and held tool hidden, then press any key or tap to return.

**Why:** Gives players an uninterrupted view without losing their current gardening task.

### [2026-10-03 13:04] Changed

**Tech:** `Catalogue.ROWS, art_source/plant_specs.json` — six bamboo varieties in Grasses.

**Dev:** Change only the category for IDs 68–72 and 80; preserve their IDs, growth days, capacities, placement layers and meshes. Update catalogue-count coverage to 24 grasses and 21 trees, including two-column tree-card coverage.

**Plain:** All six bamboo varieties now appear in the Grasses seed category.

**Why:** Keeps related plants together so they are easier to find.

### [2026-10-03 13:04] Fixed

**Tech:** `art_source/build_tools.py, assets/tools/can.glb` — rounded, attached can handle.

**Dev:** Replace the angular floating rear handle with a curved enamel loop, two body-mounted collars and a dark grip. Adjust first-person placement to keep the loop in frame. Rebuild the can GLB and complete hand-tools source in an isolated Blender scene; support targeted --only exports. Verify the handle in actual native and browser hand views and confirm all source-library images are present.

**Plain:** The watering can has a rounded handle that joins its body neatly and fits the hand view.

**Why:** Makes the can more believable and comfortable to look at.

### [2026-10-03 13:04] Added

**Tech:** `GardenTools.repeat_mouse` — held desktop watering.

**Dev:** Add watering to held mouse tool repetition, respecting the existing cooldown, aim, can upgrades, menus, photo mode and day-transition guards. Release stops watering; a return-from-view click is canceled until release.

**Plain:** Hold and sweep the watering can across the ground to water an area.

**Why:** Makes watering larger areas easier without repeated clicking.

### [2026-10-03 12:40] Fixed

**Tech:** `botanical_additions_forms.py/climber`, `assets/plants/plant_09.glb`, `assets/plants/plant_10.glb` — revised Sweet pea and Clematis flowers.

**Dev:** Preserve IDs 9 and 10 and their foliage envelopes while rebuilding flowers with explicitly triangulated curved petals. Sweet pea has banner, wing and keel petals; Clematis has outward-facing sepals and fine cream stamens. Export matching buds and refresh catalogue portraits, with packed opaque PBR materials. Read revised sources last during growth rebuilds. Validate both renderers, previous placement envelopes, growth/preview contracts and the full game suite; record player Update 17.

**Plain:** Sweet pea and Clematis now have clearer, naturally shaped flowers that face out into the garden.

**Why:** Makes these climbing flowers easier to recognise and enjoy up close.

### [2026-10-03 12:40] Added

**Tech:** `GardenCatalogue`, `GardenSeedCollection`, `botanical_additions.blend`, `build_plant_growth.py` — ten ornamental grasses and twenty cacti/succulents.

**Dev:** Append IDs 106–135 without changing existing rows, growth days or save schema 2. Add a compact two-line category button, common/botanical-name search, 30 mature GLBs, species-specific early growth meshes and model-rendered portraits. Author ribs, areoles, spines, joined pads, patterned blades, branching seed heads, fleshy rosettes, tubular jade leaves and split living stones from botanical references. Keep succulent surfaces opaque, disable leaf wind and restrain instance deformation. Preserve the 300-pixel ornate menu and plain shortcut text. Add coverage for catalogue counts, packed surfaces, rigid organ rendering and responsive category browsing. Full asset/runtime suite, read-only source-library checks, browser package/security checks and actual Chrome save migration tests pass; new plant IDs survive a browser save. Record player Update 16.

**Plain:** The seed collection now offers ten more grasses and a new category of twenty cacti and succulents.

**Why:** Gives gardeners more recognisable plant shapes and textures to combine in their gardens.

### [2026-10-03 12:22] Fixed

**Tech:** `web/save-format.js/validateSave` — accept saved watered-ground patch records.

**Dev:** Match `GardenTools.water_ground` by validating each patch's finite `x`, `z`, `radius` and `until` fields instead of treating watered ground as scalar terrain offsets. Preserve save bytes and migration archives without conversion, including expired patches. The deployed validator reproduced the reported startup message with a valid watered save; validation fails before Godot starts or autosaves. Cover v1/v2 encrypted copies, migrated-save reloads, later progress, malformed-patch rejection and unchanged databases in Chrome and WebKit. Verify watered saves in the existing exported Godot runtime and retained bytes on mount failure; record player Update 15 and check update dismissal, the browser loader, package and security checks. Publish clean source commit `46225f4` as production deployment `def7b039` and verify live encrypted transfer, exact-byte import, actual Godot startup, watered-save reload, unchanged source storage and retained latest progress; GitHub Actions passes.

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
