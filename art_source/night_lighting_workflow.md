# Torch and garden lights

`night_lighting.blend` is the editable source library for the carried torch,
path lantern, garden lamppost and garden floodlight. Its separate scene keeps
the interactive Blender scene and preferences intact. Models use metres,
Godot Y-up, and the garden's existing packed brushed-metal PBR maps.

Run `build_night_lighting.py` inside Blender to rebuild the four GLBs and
`night_lighting_manifest.json`. Run Blender exports sequentially with normal OS
access as described in the root AGENTS.md. The source library places models
side by side for editing; exports retain individual origins at their base.
The builder writes the source material's pigment multiplier into glTF's
`baseColorFactor`, preserving the colour over the packed brushed-metal map.

Import the assets in Godot, then regenerate only their presentation assets:

```sh
Godot --headless --path . --script tools/export_shop_models.gd -- --lighting-only
Godot --rendering-method gl_compatibility --path . --script tools/render_ornament_cards.gd -- --lighting-only
Godot --rendering-method gl_compatibility --path . --script tools/render_tool_cards.gd -- --torch-only
```

The GLBs contain emissive diffusers. `GardenNightLights` adds actual runtime
lights, follows the camera with the torch, and applies dusk/dawn brightness.
The eight-light local budget includes the torch and nearby Moon Garden lamps;
at most two spotlights cast shadows. Distant lamps retain their visible glow.
New lamp surfaces keep their authored PBR materials during habitat preparation.

Placed fixtures use the existing decoration save records, rotation, movement,
surface targeting and refund rules. The torch is included, independent of the
selected gardening tool, and starts stowed each session. Save schemas and
catalogue identities are unchanged.

Validate with `python3 tests/check_night_lighting.py`, the Blender source
checker's `--night-lights-only` option, and Godot `-- --night-lights-test`.
The game test uses an isolated temporary garden. A visible run also captures
matching torch-off, torch-on and placed-light views in `captures/night-lighting`.
