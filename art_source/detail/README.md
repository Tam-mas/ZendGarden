# Shop and wildlife detail workflow

The game loads these original Blender-authored models directly. The source files contain editable mesh groups arranged in a gallery, with packed textures. Sizes, ground origins and the existing gameplay systems are retained. Kangaroo models are updated, including the joey variant, while automatic kangaroo visits remain disabled.

| Source | Runtime assets | Generator |
| --- | --- | --- |
| `art_source/shop_library.blend` | All 11 items in `assets/shop/` | `art_source/build_shop.py` |
| `art_source/companions.blend` | Cat and dog | `art_source/build_companions.py` |
| `art_source/wildlife_library.blend` | Rabbit, kangaroo, kangaroo with joey, songbird, native bird, frog, bee, butterfly, dragonfly, firefly, fish | `art_source/build_wildlife.py` |

`common.py` provides Y-up authoring, bevels, turned profiles, anatomical surface fusion, UV mapping, deterministic 512-pixel material maps and export. All textures are generated locally from numeric patterns; no external art licensing or network dependencies are involved. Materials use colour, tangent-space normal and roughness textures. Glass, water, eyes and glowing elements use separate material settings.

Run the three generators sequentially in separate Blender background processes using `art_source/workshop.blend`, or use `art_source/rebuild.sh` for the entire project. On this Mac, use approved normal OS execution as described in the root AGENTS.md. The generators create new dedicated scenes and do not change user preferences. When driving through Blender MCP's background bridge, provide its existing window through `bpy.context.temp_override(window=bpy.data.window_managers[0].windows[0])` around the generator call. The MCP run used a separate workshop process, preserving the interactive scene.

To rebuild only the greenhouse, run `blender --background art_source/shop_library.blend --python art_source/build_shop.py -- --only greenhouse`. This uses the gallery’s existing materials, tolerates Blender’s numeric naming suffixes, and replaces only the greenhouse in its source library and GLB. Roof pane axes are explicit: length follows the slope, width follows the ridge, and thickness is perpendicular to the roof. `python3 tests/check_greenhouse.py` checks the actual exported transforms and all eight sloping pane bays; it is included in the test runner.

Meshes are joined by material and articulation parent to limit draw calls. Each GLB is self-contained. Godot import files enable mesh LODs and embedded Basis Universal textures; this avoids per-model extracted PNG copies. The setting is documented in [Godot's GLTFState reference](https://docs.godotengine.org/en/stable/classes/class_gltfstate.html#enum-gltfstate-handlebinaryimagemode). Fine detail is intended for close garden views; physical mobile-device performance remains to be measured.

## Animation and interaction contracts

- Companions retain `Body`, `Head`, `Tail`, `EarL`, `EarR`, `FrontL`, `FrontR`, `BackL`, `BackR` pivots. Numeric Blender suffixes are permitted.
- Flying wildlife retain two wing pivots. The runtime sets their `side` metadata and exposes them directly to the existing wing animation.
- Ground visitors expose a direct `Head` pivot.
- Animal forward direction is local -Z, except fish, which use +X to match the existing pond movement.
- Sign text remains two Godot Label3D children; the lantern light remains a Godot OmniLight3D. Bath water, pond fish height, placement prices and save data stay compatible.
- `tools/export_shop_models.gd` refreshes `.tscn` inspection scenes without overwriting the authored GLBs.

## Verification

Run `zsh tests/run.sh` for asset validation, real imported-model joint checks, wildlife facing checks and visible gameplay smoke tests. `tests/check_assets.py` requires embedded images and UVs and caps each detailed model at 65,000 triangles. `tests/ambience.gd` checks real full-height triangles at all ten greenhouse side posts.

Run `blender --background --python tests/check_blender_sources.py` to reopen all source libraries and check missing image files. Run `blender --background art_source/workshop.blend --python art_source/render_details.py` to render the exported GLBs into `captures/details/`; this verifies export appearance rather than only the authoring viewport. Generated review captures are ignored by Git.
