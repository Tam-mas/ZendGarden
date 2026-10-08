# Cohesive garden areas

The current finish and path construction are documented in [the realism pass](REALISM.md).
That pass replaces the bluestone/pale-flag contrast below with one weathered stone
family and preserves the connection, terrain and material guarantees here.

All ten habitats share a material, planting and lighting baseline while keeping their own shapes, palette and gardening activities. The third source pass is `art_source/area_cohesion.py`, installed after `area_refinement.py` by `build_distinct_areas.py`. Rebuild each area sequentially through Blender MCP with `build_one(index)`. The builder restores the user's scene and selection, writes the existing packed Area libraries and retains the terrain grids and collection slot identities.

## Material standard

Preserve existing pigment, normal and roughness textures. Author real metre UV scale, keep timber grain along each board's longest direction and retain cylindrical bark UVs. Stone repeats at 1.15 m, brick at 1.35 m and clay at 0.85 m; timber grain uses metre coordinates. Avoid adding lighting or perspective to texture pigments.

`GardenAreaMaterials` applies the same native shader profiles to authored habitat geometry and furnishings placed in those areas. Existing editable ground and bed shaders retain precedence.

| Surface | Roughness range | Finish |
| --- | --- | --- |
| Timber and bark | 0.72–0.94 | Quiet grey weathering and dirt at the foot |
| Stone | 0.79–0.97 | Restrained relief and a slight moss-coloured foot stain |
| Terracotta | 0.82–0.98 | Matte clay with a darker ground-contact band |
| Metal | 0.34–0.60 | Controlled highlights; preserve the original metal factor |
| Brick | 0.78–0.96 | Worn mineral finish with subtle contact dirt |
| Soil | 0.96–1.00 | Low sheen; changeable bed surfaces keep their existing controls |
| Shadecloth and fallen leaves | 0.94 | Preserve woven openings and mapped leaf colour |
| Glass | 0.16 | Pale neutral tint; preserve pane transparency |

Leaf litter reuses the established botanical pigment/normal/roughness workflow. Its source colour maps are packed with the other area textures. Small litter, twigs and pebbles share one detail pivot per area and do not cast disproportionate shadows. Their source meshes remain shallow, opaque geometry.

## Entrances and planted margins

A continuous bluestone trail follows the shared garden boundary, with paired signs every garden row. Fitted entrance stones lead into all ten areas. The orchard route stays outside its fence; the kitchen route turns through its arch; the glasshouse route reaches its open front. Paths follow the original height field, participate in native terrain editing/collision and reserve planting clearance. Landmark trees and authored rocks are kept clear of entrances.

Use irregular clusters of the existing detailed low plants: fine grasses, sedges, mondo, acorus and small ferns. Match their palette to the habitat, vary orientation and size, and retain clear collection pockets and stone footprints. Mix a little litter, fine twigs or pebbles into the margins rather than evenly spacing identical plants. These decorative plants use the existing batched flora workflow and follow terrain edits. Common world-space meadow texture blends back in near every boundary, including the formal gardens; dry terraces retain their sandy interior.

## Stream divide

The former joining lawn has been replaced by a protected alpine ravine with
three stone bridges and connected bank paths. See [RAVINE.md](RAVINE.md) for
its shared height data, Blender source, path routing, saved-garden recovery and
physical/visual checks. Plot centres and the ten garden milestones remain intact.

## Light and colour

`GardenWorldLighting` owns a shared AgX exposure, neutral daylight white balance, warmer low sun, cool evening ambient light and smaller contact shadows. Woodland and waterside atmosphere blends with distance through the physical world, including at area boundaries. Weather adds its existing cloud/rain response to that baseline. There is no exposure jump when the atlas selection changes. Time, weather, shade controls and saved garden progress retain their existing behaviour.

Run `Godot --rendering-method gl_compatibility --path . -- --cohesion-review` for forty actual game views: morning, midday, dusk and rain in every area, plus five entrance details. Captures go to `captures/garden-cohesion` using an isolated review save. Use Forward+ for the second renderer comparison. The atlas previews continue to come from `--areas-test`.

`tests/area_cohesion.gd`, included in `--areas-test`, traverses every new entrance with the actual player capsule and crosses the shared trail seams. It also checks correctly facing collision, planting clearance and matching collision after a terrain edit. Run the full `tests/run.sh`, `tests/check_areas.py` and read-only background Blender source checks as described in the refinement notes.
