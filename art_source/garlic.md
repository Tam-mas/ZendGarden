# Garlic (catalogue ID 298)

Garlic is an append-only Produce entry, searchable as **Allium sativum** in the
Fruit & vegetables collection. It takes 12 ideal watered game days, prefers sun,
grows in autumn/winter/spring, and uses the existing gathering and basket rules.
Its 0.62 m display height and partly exposed bulb are game presentation choices.

The model has nine alternate, flat blue-green blades, overlapping pale leaf
sheaths, an ivory papery bulb with eight subtle clove divisions and violet blush,
a basal plate and fine roots. Separate Seedling, Juvenile and Bulb-forming meshes
work with all five game growth states. The bulb uses soil-level local attachment
channels so growth stays anchored. Shared packed botanical PBR maps keep source
and GLB exports portable; only leaves receive wind. The mature model has 4,090
triangles and the supplemental stages total 3,954 triangles.

Morphology: [RHS garlic profile](https://www.rhs.org.uk/plants/858/allium-sativum/details)
and [RHS garlic growing guide](https://www.rhs.org.uk/vegetables/garlic/grow-your-own).
No reference photographs are distributed with the asset.

Rebuild in a separate approved Blender process, preserving the interactive scene:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python art_source/build_garlic.py
/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python tests/check_blender_sources.py -- --garlic-only
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
/Applications/Godot.app/Contents/MacOS/Godot --rendering-method gl_compatibility --path . --script art_source/render_plant_cards.gd -- --ids=298 --review --portraits --stages
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/garlic.gd
```

`garlic.blend` contains five meshes with packed images. The generator only writes
the new garlic assets and appends/replaces its manifest entries. Existing IDs,
earlier exports, saved gardens, and the in-game release history remain stable.
