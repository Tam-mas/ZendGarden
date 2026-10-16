# Detailed botanical library

## Second mushroom collection (IDs 288–297, release 73)

The catalogue now has **298 entries**, including twenty mushrooms. The second
collection lives in `mushrooms_02.blend`, with its own fifty meshes and packed
textures. `mushroom_expansion_geometry.py` adds ten distinct forms without
changing the first collection's geometry or exports. `mushroom_data.py` keeps
all twenty identities stable. Run `build_mushrooms.py -- --new-only` to write
only the additions; the normal full rebuild writes the two libraries sequentially.
The audit manifest merges entries from each collection rather than dropping the
other library's records.

| ID | Name | Species | Authored detail |
| --- | --- | --- | --- |
| 288 | Turkey tail | Trametes versicolor | Thin overlapping shelves with concentric ochre, grey and cream bands |
| 289 | Scarlet elf cup | Sarcoscypha coccinea | Open red interiors, pale outer walls and a hardwood twig base |
| 290 | Common puffball | Lycoperdon perlatum | Pear-shaped bodies, modelled surface spines and dark apical pores |
| 291 | Collared earthstar | Geastrum triplex | Curled, thick star rays beneath round spore bodies |
| 292 | Shaggy parasol | Chlorophyllum rhacodes | Broad pale caps, brown scales, slender stems and rings |
| 293 | Saffron milkcap | Lactarius deliciosus | Depressed orange caps, concentric surface rings and orange gills |
| 294 | Verdigris agaric | Stropharia aeruginosa | Blue-green domes, pale flecks, stem rings and dusky gills |
| 295 | Wood blewit | Lepista nuda | Lilac caps, thick stems and pale violet gills |
| 296 | Black trumpet | Craterellus cornucopioides | Hollow dark funnels with thin wavy rims |
| 297 | Golden coral | Ramaria aurea | Dense, repeated forks with fine golden tips |

Use the same packed botanical smooth-tissue PBR maps, rigid materials, local
attachment channels and young-stage contracts as the first collection. The new
shapes have appropriate player labels for shelves, cups, spore bodies, unfolding
rays, trumpets and coral branches. Young bodies are authored at 16% / 30% of
mature size, and one continuous organ-size curve crosses the forming-to-mature
handoff; batching uses that same size curve. Display heights of 0.16–0.42 m and 7–10 growing
days are game design choices. Earlier catalogue records, model files, the first
Blender source library and save formats remain unchanged.

Morphology references include the [Woodland Trust mushroom guide](https://www.woodlandtrust.org.uk/blog/2025/11/types-of-mushroom/),
[earthstar](https://www.woodlandtrust.org.uk/trees-woods-and-wildlife/fungi-and-lichens/collared-earthstar/),
[bracket fungi](https://www.woodlandtrust.org.uk/blog/bracket-fungi-identification/),
[scarlet elf cup](https://www.first-nature.com/fungi/sarcoscypha-coccinea.php),
[shaggy parasol](https://www.first-nature.com/fungi/chlorophyllum-rhacodes.php),
[saffron milkcap](https://www.first-nature.com/fungi/lactarius-deliciosus.php),
[verdigris agaric](https://www.first-nature.com/fungi/stropharia-aeruginosa.php),
[wood blewit](https://www.first-nature.com/fungi/lepista-nuda.php) and
[black trumpet](https://www.first-nature.com/fungi/craterellus-cornucopioides.php).
No reference photographs are distributed with the models.

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python art_source/build_mushrooms.py -- --new-only
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
/Applications/Godot.app/Contents/MacOS/Godot --rendering-method gl_compatibility --always-on-top --path . --script art_source/render_plant_cards.gd -- --ids=288,289,290,291,292,293,294,295,296,297 --review --portraits --stages
python3 tools/compose_mushroom_reviews.py --new-only
python3 tests/check_mushrooms.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/mushrooms.gd
```

Use approved normal OS access for Blender and Godot as in the root execution
notes. Reviews are under ignored `captures/mushrooms-02/`. Each ten-species
library retains its own 350,000 mature / 180,000 growth triangle budget, plus the
existing 60,000 mature / 18,000 growth limits per mushroom. The source checker’s
`--mushrooms-only` option checks both libraries. Asset and runtime tests cover all
twenty species, scientific-name search, every growth stage, rigid surface maps,
local attachments, batching and mixed legacy/new save restoration.

## Mushroom collection (IDs 278–287, release 72)

The first mushroom release brought the catalogue to **288 entries**. `mushroom_data.py` records the ten identities;
`mushroom_geometry.py` builds their species silhouettes with the existing shared
Blender primitives. `build_mushrooms.py` writes only `mushrooms.blend`, the ten
mature GLBs and ten supplementary growth GLBs, appends their manifest entries
and regenerates the measured height table. The packed editable library contains
50 meshes. Rebuild it last, after the older botanical builders, as in `rebuild.sh`.
The separate Blender process preserves the interactive scene and preferences.

| ID | Name | Species | Authored detail |
| --- | --- | --- | --- |
| 278 | Fly agaric | Amanita muscaria | Red caps, raised pale scales, white gills, stem rings and bulbs |
| 279 | Porcini | Boletus edulis | Chestnut domes, stout stems and pores beneath caps |
| 280 | Golden chanterelle | Cantharellus cibarius | Wavy golden funnels and forked underside ridges |
| 281 | Pearl oyster | Pleurotus ostreatus | Layered grey fans, side stems, gills and hardwood base |
| 282 | Pink oyster | Pleurotus djamor | Pink fans, pale pink undersides and hardwood base |
| 283 | Shiitake | Lentinula edodes | Brown scaled caps, pale gills and hardwood base |
| 284 | Common morel | Morchella esculenta | Recessed honeycomb cells and raised tan rims |
| 285 | Lion’s mane | Hericium erinaceus | Cream lobes with hanging tapered spines on hardwood |
| 286 | Amethyst deceiver | Laccaria amethystina | Slender violet stems and small wavy purple caps |
| 287 | Shaggy inkcap | Coprinus comatus | Tall white caps, downward flakes and dark lower margins |

The collection reuses packed botanical smooth-tissue colour, normal and
roughness maps through `Surfaces`, with species pigments and modelled relief.
All tissue is rigid and uses the existing local organ-attachment channels;
internal Seedling/Juvenile/Buds names retain runtime compatibility while player
labels describe pins, young mushrooms and developing caps. Heights of 0.22–0.36 m
are garden display choices, and shade preferences and 7–10 growing days follow
the existing game's care rules. These are ornamental collection entries, separate
from Produce, with no pollinator claim. Existing IDs 0–277, their mature/growth
exports, saves and update dismissals are preserved.

Reference morphology: [fly agaric](https://www.woodlandtrust.org.uk/trees-woods-and-wildlife/fungi-and-lichens/fly-agaric/),
[porcini](https://www.woodlandtrust.org.uk/trees-woods-and-wildlife/fungi-and-lichens/penny-bun/),
[chanterelle](https://www.woodlandtrust.org.uk/trees-woods-and-wildlife/fungi-and-lichens/chanterelle/),
[morel](https://www.first-nature.com/fungi/morchella-esculenta.php),
[lion’s mane](https://www.first-nature.com/fungi/hericium-erinaceus.php) and the
[Woodland Trust mushroom guide](https://www.woodlandtrust.org.uk/blog/2025/11/types-of-mushroom/).
References inform the model shapes; no photographs are included in the assets.

Run these commands sequentially, with approved normal OS access for Blender
and Godot as described in the root execution notes:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python art_source/build_mushrooms.py
/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python tests/check_blender_sources.py -- --mushrooms-only
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
/Applications/Godot.app/Contents/MacOS/Godot --rendering-method gl_compatibility --always-on-top --path . --script art_source/render_plant_cards.gd -- --ids=278,279,280,281,282,283,284,285,286,287 --review --portraits --stages
python3 tools/compose_mushroom_reviews.py
python3 tests/check_mushrooms.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/mushrooms.gd
```

The review composer requires Pillow. Portraits are game renders; labelled mature
and five-stage contact sheets are under ignored `captures/mushrooms/`. The ten
mature models total 183,384 triangles and growth models total 86,416, within the
separate 350,000/180,000 collection budgets and existing per-model limits.
General plant, growth, attachment, family and catalogue checks cover all 288
entries. The mushroom runtime regression covers search, stage visibility, rigid
materials, cap attachments, batch refresh and mixed old/new garden save restores.
Physical mobile performance has not been measured.

## Current full botanical art pass

The current catalogue has **218 plants**. `plant_art_sample.blend` preserves the
approved ten studies. `plant_full_00.blend` through `plant_full_17.blend` contain
the other 208 mature plants and their seedling, juvenile and attached-bud meshes.
The source manifest maps each plant to its packed editable library. Historical
builders described below must be followed by the sample and full art exporters.

Run `build_full_plant_art.build(batch)` in isolated Blender MCP background mode,
with batch numbers 0–17 **sequentially**. The CLI supports `-- --batch N`.
`rebuild.sh` includes these final overrides. The generators preserve the active
scene, approved sample exports, catalogue IDs, measured heights and placement
envelopes. Family generators and reference JSONs use the `plant_full_` prefix.
Generated tissue maps stay as WebP sources; GLBs embed 256px pigment maps and
existing normal/roughness maps. No runtime rendering settings are changed.

After import, run `tests/check_plant_art_full.py`, the existing plant/growth,
fruit, flower and bush asset checks, and `tests/plant_art_full.gd`. Render selection
portraits with `render_plant_cards.gd -- --ids=...`, excluding the approved ten.
`review_plant_full.gd -- --before` stores matched frames before replacement;
run it again after import, or add `-- --stages --ids=...` for growth stages.
These tools use ignored captures and never load a personal garden save.

The remaining sections document the earlier construction passes.

## Ten-plant art sample (release 59)

The current overrides are Rose (20), Japanese maple (30), Golden forest grass
(109), Mexican snowball (124), Cattleya orchid (148), Slipper orchid (149),
Cornflower (158), Snowdrop (174), Tropical hibiscus (198) and Hardy fuchsia (212).
`build_plant_art_sample.py` builds their mature foliage, flowers, seedlings,
juveniles and attached buds into `plant_art_sample.blend`. Its three geometry
modules have no scene or file side effects on import. Botanical references and
ImageGen prompts are recorded alongside them. The two 512px tissue sources are
WebP; exported GLBs embed their maps using the existing compressed-image imports.

**Run this builder last**, after the older libraries and growth generators, so
their original exports do not replace the sample. In a separate Blender MCP
process, add `art_source` to `sys.path`, import `build_plant_art_sample`, then call
`build_plant_art_sample.build()`. It creates an isolated scene, restores the
previous scene and writes only the sample's source, twenty GLBs and ten entries
in each manifest. Older source libraries, catalogue IDs, authored sorting heights
and save formats are preserved. The source is deliberately uncompressed for
compatibility with the installed Blender MCP's background reader.

The four older sample IDs use the existing attached-bloom metadata so their
flowers and growing tips open around their own stems. Leaf/petal material names
retain cultivar colouring, and succulent materials retain rigid tissue. No
quality presets, batching, LOD, wind shaders, lighting or resolution settings are
changed by this pass.

Before replacing assets, run `art_source/review_plant_sample.gd -- --before` in
Godot. Afterwards run it without `--before` for matched mature, distant and
five-stage captures under `captures/plant-sample/`. Refresh the ten selection
portraits with `art_source/render_plant_cards.gd -- --ids=20,30,109,124,148,149,158,174,198,212`.
Run the existing exported-asset checks plus `tests/plant_art_sample.gd`; the
focused test covers attachment channels, 50 growth-stage transitions, rigid
succulents and cultivar colours after save restoration. Physical mobile FPS has
not been measured.

## Original libraries and earlier expansions

All 60 catalogue plants use the editable meshes in `botanical_library.blend` and the exported `assets/plants/plant_00.glb` through `plant_59.glb` files. Plant IDs, mature placement envelopes, height variation, wind, growth and harvest groups are preserved.

`botanical_forms.py` defines species silhouettes and branching. `botanical_detail.py` supplies curved, UV-mapped blades, cupped petals/leaves, finer stems and fruit surfaces. It is a separate subclass so plant detail changes do not modify the shared geometry used by other generators. The exporter packs the source textures and embeds colour, normal and roughness maps in each GLB. Godot keeps embedded maps compressed; obsolete per-plant extracted PNG copies are removed. `GardenArt.add_leaf_wind` passes these maps to the wind shader.

Rebuild with a separate Blender process, following the execution requirements in the root AGENTS.md:

```sh
"/Applications/Blender.app/Contents/MacOS/Blender" --background art_source/workshop.blend --python art_source/build_botanicals.py
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . --editor --import
"/Applications/Godot.app/Contents/MacOS/Godot" --path . --script art_source/render_plant_cards.gd
zsh tests/run.sh
```

For matched comparison images, run `tools/preview_plants.gd -- --before` in Godot before changing the assets. Copy the original GLBs to `captures/plants/before-assets/` and the current leaf shader to `captures/plants/before-leaf.gdshader` to keep a reproducible baseline. The preview uses those originals when present. This saves all 60 portraits and camera framing under `captures/plants/`. After rebuilding/importing, run the same script without `--before` to produce the matching new portraits. `--raw` optionally reads exported GLBs directly for rapid inspection before Godot import; use imported assets for final review. Run `python3 tools/compose_plant_reviews.py` with Pillow available to assemble six labelled category sheets and a highlights sheet. Every pair uses the same camera, model rotation, scale, lighting and background; each species has its own framing. Add `--rendering-method gl_compatibility` before `--script` for compatibility portraits in a separate `after-compat/` folder. Captures are review artifacts and are ignored by Git.

`tests/check_plants.py` verifies complete species coverage, embedded PBR maps, UVs, finite coordinates and geometry budgets. Pass `--baseline captures/plants/before-assets` when a copy of the earlier GLBs is available to check placement dimensions. `tests/plant_models.gd` verifies that wind materials retain all three texture maps and that growth/harvest bloom groups survive loading. The full smoke suite covers growth, mature height, pruning, placement and gameplay. Physical mobile-device performance has not been measured.

## 46-plant expansion (IDs 60–105)

The first expansion brought the catalogue to 106 entries. `botanical_expansion_forms.py` contains the
new morphology, `botanical_geometry.py` holds side-effect-free primitives shared
with the original builder, and `build_botanical_expansion.py` exports only the
46 additions into `botanical_expansion.blend`. The original 60 GLBs are preserved.
See `botanical_expansion_references.md` for species traits and references.

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python art_source/build_botanical_expansion.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
/Applications/Godot.app/Contents/MacOS/Godot --always-on-top --path . --script art_source/render_plant_cards.gd -- --new-only
/Applications/Godot.app/Contents/MacOS/Godot --always-on-top --path . --script art_source/render_plant_cards.gd -- --new-only --review
python3 tools/compose_expansion_reviews.py
```

The portrait composer requires Pillow. Use the bundled workspace Python if it is
not installed in the system Python. `--ids 60,61` after Blender's `--` limits GLB
exports for iterations while rebuilding the complete editable source gallery.
Compressed embedded-image import settings must be retained for new GLBs.

Budget: original 60 remain below 2.6M triangles, the new collection below 3.6M,
and each model below 200k before Godot's generated LODs. The expansion has a
higher proportion of trees and woody plants than the original collection.

## Growth stages and individual shape (all 136 plants)

`build_plant_growth.py` reads the two mature botanical libraries without changing
or saving them. It builds separate Seedling, Juvenile and Buds meshes in
`plant_growth.blend`, exports `assets/plants/growth/growth_00.glb` through
`growth_105.glb`, and records species families, bounds and geometry budgets in
`plant_growth_manifest.json`. The generated `scripts/plant_profiles.gd` contains
mature model heights for catalogue filters; it is included in web exports where
source JSON is excluded. Bud positions follow the mature bloom geometry, with
growing tips for plants without a harvest mesh. All supplementary models embed
packed colour, normal and roughness textures. Retain compressed embedded-image
imports (`gltf/embedded_image_handling=2`) instead of extracted PNG copies.

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python art_source/build_plant_growth.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
python3 tests/check_plant_growth.py
/Applications/Godot.app/Contents/MacOS/Godot --always-on-top --path . --script tests/plant_improvements.gd -- --review
/Applications/Godot.app/Contents/MacOS/Godot --always-on-top --path . -- --improvements-test
```

When run by Codex, Blender and Godot use approved normal OS access, as described
in AGENTS.md. A separate process preserves the interactive Blender scene. The
read-only `tests/check_blender_sources.py` now includes the growth library.

The supplementary meshes total 572,200 triangles, below the 900,000 budget.
Runtime stages change at 20%, 52% and 78% growth, with full blooms/fruit at 100%.

Fruit trees retain branch attachment positions through budding and ripening.
`fruit_tree_geometry.py` varies fruit size, hanging angle, occupied twigs and
pigment with a separate repeatable random stream, preserving the existing
trunks, branches and foliage. The grouped `BloomFruit` and `BudsFruit` meshes
store attachment X/Y in a second UV layer and attachment Z in two colour bytes.
The fruit growth shader decodes glTF's flipped V coordinate and grows each organ
locally before applying the saved plant shape. Shared size materials at 32 steps
retain efficient batching; previews and selection outlines use the same growth.
Other flowers and produce retain their existing stage behaviour.

For a focused rebuild of the 13 trees, run a separate approved Blender process
with `--background --python art_source/build_fruit_trees.py`. This preserves all
other plant exports, seedlings and juveniles, verifies unchanged foliage, and
updates the three editable libraries and their manifests. Before writing, it
creates verified recovery copies under ignored
`captures/fruit-tree-review/rebuild-backup/`, excluded from Godot imports.
The standard mature and growth builders also reproduce the fruit geometry.
After importing, run `tests/fruit_trees.gd` in Godot with both rendering methods
to check imported anchors, growth, outlines, previews and batch updates.
The mature model and original height/pruning scale remain authoritative.
Supplementary scenes load only when an early stage is needed; hidden stages do
not render. Shape bending and twist stay coherent across mature foliage,
flowers, growth stages, placement previews and target outlines. Forward+ uses
per-instance shader values. Compatibility/WebGL uses private material values
for planted specimens, while decorative plants keep shared zero-shape materials;
this avoids the hardware-limited global instance-uniform buffer. Preview and
outline materials preserve these values as well as the source PBR maps.
Orientation and shape seeds persist in existing version-2 saves; older saves
receive repeatable values derived from plant ID and position.

The focused test covers stage visibility for every species, search/filter
results, favourites, recency, care explanations, targeting and saved appearance.
The in-game fixture uses the normal menus/action dispatcher and captures desktop
and phone views under `captures/plant-improvements/` without using the personal
save. The full smoke suite also checks a 142-plant layered bed. Physical mobile
hardware performance remains unmeasured.

Shop thumbnails are rendered from the existing ornament GLBs with
`tools/render_ornament_cards.gd` and saved under `assets/ui/shop/`.

## Grasses and cacti/succulents (IDs 106–135)

The catalogue now has 136 entries. See `botanical_additions_references.md` for the ten grasses and twenty cacti/succulents and the revised Sweet pea/Clematis flowers. `botanical_additions.blend` is an isolated 32-plant source library. Rebuild it after the two older libraries and before growth stages. Growth sources load the additions last so IDs 9 and 10 use revised flowers. Both additions and growth builders accept `-- --ids 9,10,106,...` to limit GLB writes. The growth library contains all 136 species. The thirty new mature meshes have a separate 900,000 triangle budget; the full mature library budget is 7,100,000. Growth stage geometry has a 900,000 triangle budget. The original 0–105 IDs, legacy growth-day conversions and schema 2 saves stay stable.

To render only additions/revisions use `art_source/render_plant_cards.gd -- --ids=9,10,106,...`, adding `--review` for large portraits or `--compat-review` with Compatibility rendering. `tools/compose_additions_reviews.py` labels the real game renders. Run `tests/check_botanical_additions.py` after generating portraits.

## Low grass collection (IDs 136–147)

The catalogue now has 148 plants. `low_grasses_data.py` and
`build_low_grasses.py` build twelve low plants with creeping runners, compact
curved blades, longitudinal sedge variegation and small flowers/seed spikes.
`low_grasses.blend` contains both mature plants and their own growth stages;
`build_plant_growth.py` preserves these entries while rebuilding earlier species.
See `low_grasses_references.md` for morphology and sources. The mature additions
use a separate 250,000 triangle budget; the full collection stays below 7,350,000.
The growth collection remains below 900,000 triangles. Catalogue IDs and saved
schema 2 gardens remain compatible. Renderers save portraits in whichever of PNG
or lossless WebP is smaller, and the game loads the selected format.

Through MCP, import `build_low_grasses` and call `build()`. It preserves the
active Blender scene and writes only its new library. Alternatively, use an
approved Blender background process with `--python art_source/build_low_grasses.py`.
Source pigment folders are ignored by Godot, since models already embed the maps.
