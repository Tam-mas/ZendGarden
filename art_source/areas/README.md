# Ten garden habitats

`../build_distinct_areas.py` builds the ten 24 × 24 metre landscapes and eighteen collection plants. They were authored through the connected Blender MCP in Blender 5.2.1. Each area has a dedicated `ZendGarden_HQ_Area_*` scene and a packed, editable source library at `../overhaul/Area_*.blend`; collection plants share `Area_Collections.blend`. The current scene and selection are restored after each export. Only generated roots in the builder's own scenes are replaced. The game uses the exported GLBs and does not require Blender.

To regenerate through MCP, inspect the current Blender scene and Object mode first, add `art_source` to `sys.path`, then import `build_distinct_areas`. Call `build_one(index)` sequentially for indices 0–9, followed by `build_specialties()`. Import the module in each tool call; individual MCP calls use fresh Python namespaces. For a background build, use approved normal macOS access and run heavy exports sequentially. Do not change preferences or overwrite the user's interactive scene.

`assets/areas/layout.json` holds names, centers, preview cameras, collection slots and terrain height grids. Runtime collision, planting, sculpting and walking query these grids. The new connected extension sits east of the existing gardens. Original expansion plots retain their coordinates; old plot indices shift by ten when saves first open in this version.

Landscape GLBs contain grouped, UV-mapped meshes, embedded surface images and independent functional pivots for canopy clearings, rain covers, glasshouse panes/vents/shade, stream gates, alpine windbreaks and lanterns. Runtime water, light, mist, wildlife and plant growth respond to saved activity controls. Narrow stair treads and bridge planks have continuous runtime collision surfaces. Existing container and equipment models provide usable benches, pots and vertical planters on first arrival.

`../garden_routes.py` authors the sampled centre lines in `assets/areas/routes.json`. Blender entrance paving and runtime planting clearance read the same routes. Every approach meets an existing inner path, stair, courtyard or crossing; Fern Gully passes around the creek head. The original eastern approach joins the shared trail through a northern Reedwater perimeter path. Main-trail bluestone uses metre-scaled running-bond joints and the existing detailed stone pigment and relief maps. Paving and matching collisions follow saved terrain edits. Ordinary plants and starter equipment use the regular gardening tools; specialist collections remain in their named pockets, and decorative landscape planting stays fixed.

## Image-generated textures

Generated with the built-in ImageGen tool and copied unchanged into this directory:

- `textures/mossy-granite.png`: moss-covered boulder and alpine terrain base color.
- `textures/aged-brick.png`: walled kitchen and glasshouse paving base color.

Mossy granite prompt: “Generate one seamless tileable square PBR base-color texture only for mossy weathered granite rock, viewed absolutely flat with no perspective. Cool grey mineral grains, irregular subtle cracks, pale lichen and roughly 25% dark forest-green moss in recessed patches, restrained cozy natural photographic detail. Neutral even lighting, no directional shadows, no highlights, no vignette, no border, no text, no objects, no 3D scene. Seamless opposite edges. 2048 square texture.”

Aged brick prompt: “Generate one seamless tileable square PBR base-color texture only for aged warm red-clay handmade brick paving in an alternating herringbone pattern with narrow sandy lime joints. Restrained terracotta, russet and ochre variations, about 8% tiny moss patches in joints, worn corners, subtle mineral marks. Absolutely flat orthographic material scan, neutral even illumination, no lighting gradients, no directional shadows, no vignette, no border, no words, no objects, no 3D scene. Seamless opposite edges. 2048 square texture.”

The texture images are packed into editable Blender sources and exported GLBs. Other surfaces use the project's deterministic normal, roughness and albedo generators. No external texture downloads are required.

## Checks and real previews

`python3 tests/check_areas.py` verifies geometry, UVs, finite normals, packed images, terrain joins, import settings and geometry budgets. `--areas-test` runs isolated save/migration, activities, walking and responsive atlas checks, including actual viewer updates after every arrival and ray checks across every terrain collision partition. Walking checks require landing and reject falling below the ground even when horizontal progress succeeds. Godot imports Blender custom properties into the node's `extras` metadata dictionary; read `ground`/`area_ground` and `collision`/`area_collision` there rather than depending on unnumbered pivot names. Compatibility and Forward+ runs capture all ten actual areas into `captures/areas`, with mature example planting and restored glasshouse bays. The images are game renders, not concept artwork. `assets/ui/areas` contains the compact atlas previews. Blender source checks run read-only in a separate approved background process.
