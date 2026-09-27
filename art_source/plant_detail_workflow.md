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
