# Botanical expansion validation — 27 September 2026

- 46 new models, IDs 60–105; 106 total catalogue entries.
- Additions: 8 Flowers, 10 Shrubs, 14 Trees, 5 Natives, 9 Produce. Grasses unchanged.
- Original 60 GLBs and catalogue identities preserved.
- `tests/check_assets.py`: pass for all 106 plants and existing game assets.
- `tests/check_plants.py`: pass; 5,737,848 total triangles, 3,301,744 in the
  expansion. Every plant below 200,000 triangles; original Cherry blossom
  remains the largest at 195,816. Geometry is measured before Godot's LODs.
- `tests/check_blender_sources.py` inside Blender: pass for all seven source
  libraries, including 92 meshes in `botanical_expansion.blend`; no missing images.
- `tests/plant_models.gd`: pass across all 106 entries. Wind overrides retain
  colour, normal and roughness textures, and growth/harvest Bloom groups exist.
- `tests/run.sh`: pass, including expanded catalogue UI, ecology/save migration,
  orders, touch controls, gardening tools and held/area gathering.
- Godot Metal Forward+ and OpenGL Compatibility: rendered all 46 new plants;
  46 distinct nonempty review PNGs for each renderer and 46 catalogue portraits.
- Visually inspected category sheets, selected close views, the striped rose's
  embedded colour texture, and the corrected leek shaft. Iterations addressed
  sparse canopies, overly flat/lobed flower forms, packed texture refreshes,
  geometry budgets and leaf/flower attachment points.

Review images are local generated artifacts in `captures/botanical-expansion/`.
Recreate them with the commands in `plant_detail_workflow.md`. They show Godot's
imported models, not illustration substitutes. Physical mobile performance and
large gardens made entirely from the new tree varieties were not profiled.
