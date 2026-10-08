# Ten trails, one garden

`area_composition.py` is the final pass installed by `build_distinct_areas.py`.
It replaces the previous decorative scatter with groups of existing botanical
models. The original stone, timber, soil and plant textures are reused. All ten
terrain grids, collection pockets, fixtures and route coordinates are unchanged.

| Garden | Composition |
| --- | --- |
| Reedwater | Reeds, iris and sedge colonies frame open water and the boardwalk |
| Fern Gully | Layered fern colonies shelter the creek and clearings |
| Limestone | Succulent pockets, small scree and silver planting soften terraces |
| Pollinator Meadow | Repeated flower ribbons and grasses frame the winding walk |
| Orchard | Herb and grass borders leave productive rows and training access open |
| Kitchen | Flowering herbs soften the outer walls and frame the entrance |
| Glasshouse | Ferns and low grasses settle the building into its surroundings |
| Stream Garden | Fern and sedge groups follow banks while keeping gates clear |
| Alpine | Graduated outcrops, scree and low silver grasses replace the rock ring |
| Moon | Silver foliage and dusk flowers frame the pool; pergola supports clear its coping |

Each planted group carries a local `composition_bed` ellipse, its planting
count and palette kind. `GardenAreaMaterials` sends nonempty profiles to the
ground shader, which feathers the existing garden loam into the grass beneath
the planting. World-space coordinates retain alignment after terrain edits.
These are surface changes, with no additional collision or saved state.
Orchard bed finishes retain the same profiles when switched or restored.
Wet banks use a darker mineral tone so shallow water meets earth naturally.

The shared trail's signs name west/east destinations. The atlas groups gardens
in the same five pairs, shows the opposite garden and retains scroll position
and keyboard focus after care. Basket requirements use spare inventory, so
neighbour requests remain reserved. Collection pots occupied by ordinary plants
explain how to free the pot; the night-photo action travels to the Moon Garden
before opening the camera. Save versions, milestones and costs are unchanged.

## Rebuild and review

Use Blender MCP with Blender 5.2: import `build_distinct_areas`, then call
`build_one(index)` sequentially for 0–9. The calls restore the original scene
and selection and write the existing packed libraries and GLBs. The stream
rebuild and checks are described in [RAVINE.md](RAVINE.md).

- `python3 tests/check_areas.py` checks all meshes, margin metadata and budgets.
- `python3 tests/check_ravine.py` checks the stream and bridge clearances.
- Run the path and connecting-trail Python audits after any geometry changes.
- Run `tests/check_blender_sources.py -- --areas-only` inside background Blender
  for read-only validation of the habitat, collection and furnishing libraries.
- Run Godot headless with `--script tests/area_atlas.gd` for atlas regressions.
- Use `-- --areas-test` and `-- --land-test` for actual activities, walking,
  terrain, recovery and save checks.
- Use `-- --cohesion-review --extension-review --refresh-atlas` for ten morning
  views, all three bridges, bank/cascade details, rain and blue-hour Moon Garden.
  Add `--resume-review` to reuse completed photographs after an interrupted run.
  Captures are written to `captures/garden-extension`; atlas images are real
  game renders. Add `--forward-review` with Forward+ for a separate capture set.

Reviews use isolated saves. The Moon Garden atlas image uses blue hour after
the dusk flowers open, keeping both the layout and its night character legible.
