# Detailed botanical library

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
