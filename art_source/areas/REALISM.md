# Garden paving and scenery review

The fourth construction pass is `art_source/area_realism.py`, installed last by
`build_distinct_areas.py`. Run background Blender sequentially with normal OS
access and `--python-exit-code 1 --python art_source/build_distinct_areas.py`.
The process preserves the interactive scene and writes the existing ten packed
Area libraries and GLBs. It keeps terrain grids, collection slots and fixture IDs.

## Review decisions

| Area | Changes |
| --- | --- |
| Reedwater | Weathered stone arrival fitted to the boardwalk; subdued timber, correctly aligned board grain, underside bearers and deck fixings. |
| Fern Gully | Warm-grey flags along the complete bank path; darker, irregular bank boulders and finer filled joints. |
| Limestone Terraces | Warm crushed-stone and sand surfaces, textured masonry and stair treads, flush first landing. |
| Pollinator Meadow | One continuous entrance-to-inner path with a tangent bend; remove the short dead-end spur. |
| Orchard Clearing | Varied stone arrival, filled joints, quieter weathered timber and preserved harvest-table access. |
| Walled Kitchen Garden | Smaller-scale reclaimed wall brick, weathered stone coping and an entrance flush with the herringbone courtyard. |
| Old Glasshouse | Brick foundation, stone sills, open gutters and downpipes; fitted courtyard approach and properly scaled shelf grain. |
| Stream Garden | Irregular groups of embedded bank stones, weathered bridge timber and a flush deck approach. |
| Alpine Lookout | Continuous entrance bend without a trailing branch, more irregular rocks, and planting clearance along the entire inner path. |
| Moon Garden | Quieter gravel, fitted segmented pool coping and weathered painted pergola timber; the approach follows the oval court edge. |

Paths use 600/900/1200mm lengths in 480mm courses with 8mm sand-filled joints.
The common trail and individual areas share world-space coursing and pigment.
All area approaches are cut against the actual common trail polygons, including
the northern bend; no cap is layered on the shared trail. Junctions and thresholds
retain their existing destinations. The joints are disjoint faces only 2mm below
the flags. Metre-lattice cuts keep saved sculpting and collision in agreement.

`authored_surface_uv` preserves the area builder's per-board UVs through the
shared exporter. Other assets retain the exporter's existing UV defaults.

ImageGen source assets and exact prompts are in [textures/PROMPTS.md](textures/PROMPTS.md).
Runtime tones are reviewed under the game's actual daylight rather than inferred
from the source swatches. Both the original pixels and Blender normal maps remain
available in the source tree.

## Verification

Run `tests/check_path_paving.py` for exported-triangle overlaps, fitted edges,
shared-trail intersections and bend coverage; `tests/check_areas.py` for mesh,
texture and botanical reservations; and the game with `--areas-test` for planting,
furniture, activities, capsule traversal and saved terrain edits. The inner-path
checks include planting clearance in Fern Gully, Pollinator Meadow and Alpine
Lookout. `--cohesion-review` captures all ten areas in four lighting conditions;
`--junction-review` adds walking-height details. Use both Compatibility and
Forward+ renderers. Add `--refresh-atlas` to save current views into the ten
in-game Atlas cards without repeating the gameplay test.
`tests/check_blender_sources.py` validates libraries read-only.
