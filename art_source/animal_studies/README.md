# Supplied animal sculpt studies

Editable, textured and animated studies made from Tam's supplied STL files through Blender MCP intake and sequential Blender authoring/export. These extend the separate cat experiment. The approved dog, fox, echidna and rabbit now replace their production garden assets, alongside the earlier supplied cat. The new wombat is a separate review study; its live garden model and selection are unchanged.

The source STLs each contain about two million triangles. Each full `.blend` preserves the dense sculpt in a hidden reference collection, alongside the lighter UV-mapped, weighted game mesh, materials and baked actions. The `_review.blend` files contain the complete editable prototype and studio without the dense reference. Their scenes have also been appended through MCP to the running Blender session; the pre-existing scene, selection, file and preferences were preserved.

| Animal | Coat and detail | Authored clips | Exported triangles, including eyes/fur |
|---|---|---|---:|
| Fox | Russet upper coat, pale throat/belly, dark boots and pale tail tip; fine laid fur, socket-fitted amber eyes | Idle, quiet four-beat walk, alert look | 66,816 |
| Dog | Golden retriever coloration matching the supplied floppy-eared shape, cream feathering, black nose, coloured mouth, short fur | Idle, four-beat walk, sniff, look, with tail wag and ear sway | 66,806 |
| Echidna | Dark face/legs and cream/golden spine bands; preserve actual spine geometry and claws | Idle, short-stride amble, snout foraging, look | 63,158 |
| Rabbit | Grey-brown agouti variation, pale underside, pink ear interiors, dark glossy eyes and short laid fur | Idle, coordinated hop with crouch/flight/landing, forage, look, independent ear flicks | 56,348 |
| Wombat | Warm grey-brown coarse coat, darker digging feet and broad bare nose, small socket-fitted eyes and short laid fur; continuous surface closes print-style slits | Idle, slow four-beat walk with a weight shift, forage, look, low standing rest, blinks and restrained ear flicks | 62,356 |

General colour references: [red fox, Animal Diversity Web](https://animaldiversity.org/accounts/Vulpes_vulpes/), [European rabbit, Animal Diversity Web](https://animaldiversity.org/accounts/Oryctolagus_cuniculus/), and [short-beaked echidna, Perth Zoo](https://perthzoo.wa.gov.au/animal/short-beaked-echidna). The supplied dog resembles a retriever, so its coat follows that anatomy rather than retaining the current game's collie markings.

The wombat's coarse coat, broad bare nose, small eyes and quiet waddle follow the [Australian Museum's bare-nosed wombat description](https://australian.museum/learn/animals/mammals/bare-nosed-wombat/) and [Tasmania's wildlife reference](https://nre.tas.gov.au/wildlife-management/fauna-of-tasmania/mammals/possums-kangaroos-and-wombats/wombat). Its source sculpt retains some stylised proportions and raised cheek fur. See [the wombat study notes](wombat/README.md) for its source, movements and validation.

## Review

Run the standalone viewer from the project root:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path art_source/animal_studies/preview
```

Select Dog, Fox, Echidna, Rabbit, Cat or Wombat, then choose a motion. Drag to orbit, scroll to zoom and press Space to pause. The previous game asset is on the left; the supplied-sculpt study is on the right. The five earlier baselines are frozen from main at `e85c209`; the wombat baseline is from `4fe13f9`, before its study began. Posed vertices determine their displayed heights, with the same lighting and fur shading. Embedded old animations are played where available; the retained dog/rabbit/cat use their familiar procedural motion. Display transforms belong to separate parent nodes so imported animation cannot override the review positions.

In the running Blender session, choose a `Zend STL — animal` scene: Idle is enabled for playback. In the NLA editor, mute Idle and unmute the desired action track to review a different motion. The saved source files keep their tracks muted for a clean rest-pose view; unmute one track to play it, and set the timeline range to its strip.

The runtime GLTF loader retains immutable tracks, since dropping fixed joint transforms produces a misleading, disjointed baseline fox. It uses named skin bindings and keeps the complete animation tracks; see the primary [Godot GLTFDocument documentation](https://docs.godotengine.org/en/stable/classes/class_gltfdocument.html). The game also retains the complete supplied rig wrapper and its facing transform beneath an independent navigation root.

Actual Godot-rendered comparison PNGs and animated GIFs are saved under each animal's `previews/`. `portraits.webp` is a contact sheet of the Blender studio renders, not an image-generated illustration. The individual studio portraits and temporary raw/close-up views are also available there.

## Texture storage

All new model maps are WebP, packed in the Blender sources and embedded in the GLBs via `EXT_texture_webp`. No duplicate PNG fallback is embedded. Godot 4.7.2 Compatibility loaded and rendered all four exports successfully.

The new wombat's model maps total 5,411,580 bytes, 47.1% smaller than their corresponding PNGs. Its separate generated coarse-fur source is 75.2% smaller in WebP. The final wombat was loaded and animated in both Godot 4.7.2 Compatibility and Forward+.

- Colour maps use quality 95 WebP.
- Normal maps and transparent fur cards use lossless WebP, with exact decoded-pixel checks against PNG before conversion.
- The final per-animal maps total **10,828,918 bytes**, compared with **29,458,219 bytes** for the corresponding PNGs: **63.2% smaller**.
- The generated neutral fur source is separately reduced from 3,118,714 bytes to 732,998 bytes, a 76.5% saving. The built-in ImageGen prompt, output path and usage are in `generation.json`.
- The echidna uses a padded triangle atlas. Ordinary automatic UV packing and normal-ray baking across thousands of thin spines produced dark seams; the atlas keeps their anatomical colours without that bleeding. Its geometry provides the spine relief, with a flat lossless normal map.
- Albedo maps describe colour; tangent normals for the other three animals are baked from the supplied sculpt. The generated fur image is used as fine colour detail, not as measured geometric depth.

The echidna atlas splits vertices at UV borders, making its GLB larger than the other prototypes despite a similar triangle count. These are desktop review budgets; a production/mobile pass should further optimise topology, vertices and texture resolution.

## Verification

`validate_animals.py` runs read-only inside Blender. It checks packed WebP maps, UVs, normalised weights with at most four influences, finite evaluated poses, loop endpoints, non-static gait motion and sampled deformed-mesh floor contact. Ground-contact checks allow rabbit flight and require the walking species to remain near the floor. All four final sources pass; their numeric reports are stored beside the sources.

`preview -- --capture` renders all clips from the actual exported GLBs, including baseline animation. `encode_previews.py` packages those frames and checks changing pixels in the prototype's half of each motion comparison. `godot_validation.json` records loaded clip names and textured surfaces. Intermediate capture frames and intake/prepared caches are excluded from Git.

A separate Blender process must be launched with approved normal OS access on this Mac, per the root AGENTS instructions. Heavy Blender jobs run sequentially. Do not launch the generator in the user's live authoring scene.

## Rebuild

The four input `intake.json` files and final `report.json` files record original triangle counts, bounds, provenance and source SHA-256. The user's original STL downloads were not modified. `import_sources.py` reproduces the isolated intake from a folder containing the four original STLs, and `inspect_sources.py` creates grounded, normalised inspection meshes:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python art_source/animal_studies/import_sources.py -- /Users/tam/Downloads
/Applications/Blender.app/Contents/MacOS/Blender --background --python art_source/animal_studies/inspect_sources.py
```

Then run one animal at a time:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background art_source/animal_studies/fox/prepared.blend --python art_source/animal_studies/build_animals.py -- fox
/Applications/Blender.app/Contents/MacOS/Blender --background art_source/animal_studies/fox/fox_review.blend --python art_source/animal_studies/validate_animals.py -- fox
```

Repeat for `dog`, `echidna` and `rabbit`. To rebuild the wombat, pass `wombat` to intake/inspection, then load `wombat/prepared.blend` with `build_animals.py -- wombat`. `species.py` stores measured asymmetric face sites and anatomical rig landmarks. `convert_map.py` uses the configured bundled Python/Pillow runtime. `refine_export.py` documents the one-time review correction to the earlier eyelid actions; the main builder now generates the corrected lids directly. Do not apply that migration to the new wombat or repeatedly to already refined files.

## Remaining production work

These supplied sculpts are a stronger anatomical starting point, especially the fox and echidna. They still contain print-style carved fur, fused details and some stylised proportions. Decimation and mild smoothing preserve those limitations. Deliberate retopology/sculpt cleanup would improve joint deformation and reduce download/vertex costs further.

The original study clips remain available for comparison. Compact `<animal>_game.blend` sources and `export/<animal>_game.glb` exports are the production versions. The dog adds petting and relaxed, grounded settling clips; the cat also adds a stretch. Navigation speed follows the measured stance timing, and rabbit travel follows its airborne hop phase. Alert and grazing states dispatch to look or forage as appropriate. The rabbit retains the supplied sculpt's rounded proportions. Sources and reports preserve that provenance.

## Production rebuild and checks

Run `promote.py -- <animal>` inside an isolated Blender process, sequentially for cat, dog, fox, echidna and rabbit. It retains approved geometry and coats, adds companion interaction actions, embeds WebP maps and writes both canonical and game exports. `promotion.json` records each hash; `model_choices.json` records the approved replacements, and the selection policy protects them from older library rebuilds.

Run `tests/check_supplied_sources.py` inside Blender for packed maps, finite poses, loop seams and sampled coat ground contact. `tests/supplied_animals.gd` checks real Godot loading, orientation, clip dispatch, navigation independence, articulated knees and planted ankle heights. The full game suite covers calling, settling, petting, sunny stretching, sniffing and both renderers. Review baselines are frozen in `baseline/`, with their hashes and commit in its manifest. Garden save data and dismissal history remain compatible.
