# Imported cat experiment

This is a separate modelling experiment. The garden's selected cat, asset paths,
behaviours and model-choice file are unchanged. The folder is excluded from Godot
resource imports and production exports.

## Review

Open `cat_study.blend` in Blender, or run the standalone Godot viewer:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path art_source/cat_study/preview
```

The current game cat is on the left and the textured STL prototype on the right.
Both have the same overall height and share lighting. The original cat's rigid
walk, breathing, ear and tail motions reproduce its companion controller; look
mode supplies a head-turn target for comparison. The prototype plays its exported
skeletal clips. Buttons or 1/2/3 select idle, walk and look. Drag to orbit, scroll to
zoom, and Space pauses. No selections or garden data are written by this viewer.

`previews/textured_quarter.png` is a Blender studio render. The comparison PNG
and GIFs are captures of the exported models rendered in Godot, not Blender shots.

## What was made

- Preserve the original two-million-triangle sculpt in a hidden reference
  collection. Normalise it to 0.52 m tall including the upright tail.
- Reduce the deforming coat to about 48,000 triangles and gently soften the
  print-scale fur ridges. The entire exported model is 57,078 triangles, including
  eyes, lids, whiskers and hair.
- Bake anatomical brown-tabby pigment, pale chest/socks and the sculpt's surface
  detail into 2048 px albedo and tangent normal maps. Normal strength is restrained
  so the fur grooves do not dominate the material.
- Add inset glossy amber eyes, slit pupils and fast independent eyelid controls.
- Add 661 short weighted alpha hair cards and thin tapered whiskers. The original
  printed whiskers remain near the muzzle; only exposed far ends were trimmed.
- Build a 24-bone rig with separate upper/lower legs and paws, soft region-aware
  weights, ear controls and three tail segments. The sculpt's asymmetrical paw
  positions determine the weighting regions; an assumed X=0 split was unsuitable.
- Bake planted-contact IK into portable FK clips: idle (8 s), look (5 s) and a
  four-beat walking cycle (1.2 s). Breathing, staggered ear flicks, gaze, blinking
  and lagged tail movement replace synchronous rigid-piece motion.

The GLB embeds its maps and is about 4.65 MiB. Smooth depth-prepass alpha and
disabled card shadows are used in this comparison viewer to avoid a stippled coat
at its viewing distance. A production integration should carry that rendering
treatment over rather than blindly using the existing alpha-hash fur policy.

## Limits and next production step

This is a decimated, triangulated printing sculpt with regional weights, not a
hand-retopologised animation mesh. The source offers a much better face/body
silhouette, but its chunky sculpted fur and muzzle whiskers still read as a sculpt
in close-ups. The blink lids are a lightweight approximation, not a complete face
rig. The leg chains use a simple upper/lower/paw layout rather than a full feline
scapula and digitigrade hock rig.

For a final cat, manually clean the cheek/whisker junctions, reduce the carved fur
into a subtler normal map, retopologise shoulders and hips, groom directional hair,
and refine eye/lid fit under the actual garden lighting. Add sit/settle, stretch
and pet interactions before replacing the companion. The prototype walk is a
slow 0.167 m/s at its authored scale; calibrate navigation speed and animation rate
together rather than using the current companion's 0.7 m/s and 1.98 multiplier.
This experiment has not changed the production model or been merged to main.

## Source and rebuild

User-supplied source: `/Users/tam/Downloads/cat.stl`, 100,000,084 bytes.

SHA-256: `6feef10196afc7ef187d469596e39e4a9caec1d1d395f06376b462c46429c11e`

The source geometry is preserved in `cat_study.blend`'s hidden reference collection;
the external STL is not moved or altered. Fur alpha reuses the project's existing
`art_source/overhaul/textures/generated/fine-fur-card.png`. Coat pigments and the
normal map are authored from geometry, not interpreted from a photograph.

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background \
  --python art_source/cat_study/build_study.py -- /path/to/cat.stl
/Applications/Blender.app/Contents/MacOS/Blender --background \
  art_source/cat_study/cat_study.blend \
  --python art_source/cat_study/validate_study.py
/Applications/Godot.app/Contents/MacOS/Godot --path art_source/cat_study/preview -- --capture
python3 art_source/cat_study/encode_previews.py  # Requires Pillow; run after capture exits.
```

Run Blender subprocesses with normal OS access as described in the root AGENTS.md.
The connected Blender MCP was used to import/inspect the sculpt and review source
data. Baking/export ran sequentially in isolated background processes; the open
interactive project and its scene were preserved.

Validation covers packed maps, UVs, finite bone transforms, normalised weights
(at most four per vertex), moving paws, loop seams and floor clearance. See
`report.json` and `validation.json` for measured results. Godot captures verify
both models and all three exported clips in the actual engine; no live garden
saves are loaded.
