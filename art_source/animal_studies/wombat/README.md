# Supplied wombat study

An editable Blender study of Tam's `/Users/tam/Downloads/wombat.stl`, kept separate from the live garden wombat. The original sculpt and its SHA-256 are recorded in `intake.json`; the download was not modified. MCP imported it in an isolated scene and added the final review scene to the running Blender session while preserving the existing project, active scene and selection.

## Shape and coat

The original has 1,999,972 imported triangles. `wombat.blend` preserves that dense sculpt in a hidden reference collection. The review source and GLB contain 62,356 triangles including eyes and 3,318 short laid fur cards, with a 21-bone rig. The game-facing orientation is included in the exported wrapper.

A 1.6 mm voxel surface closes thin print-style fur folds before reduction. Selective relaxation smooths the coat while protecting the digging paws and claws. Fine colour variation and a restrained tangent normal bake supply the smaller fur detail. Some of the supplied sculpt's raised cheek fur and proportions remain.

The coat is warm grey-brown with a slightly darker back, softer flanks, darker feet and a broad charcoal nose. Small glossy eyes fit the measured asymmetric sockets; lids blink and the ears occasionally flick. The new generated coarse-fur image supplies colour microdetail. It is not a measured depth scan. `generation.json` retains the exact built-in ImageGen prompt, original image path and conversion settings.

The six new model maps are all WebP: 5,411,580 bytes compared with 10,231,299 bytes for their PNG equivalents, a 47.1% saving. Normal and transparent fur maps use lossless conversion with decoded-pixel equality checks; the albedo uses quality 95. The separate generated fur source is 997,626 bytes versus its 4,027,246-byte PNG original, 75.2% smaller. Material maps are packed in both Blender sources and embedded in the GLB through `EXT_texture_webp`, with no PNG fallback.

## Movement

| Clip | Duration | Behaviour |
|---|---:|---|
| Idle | 9 s | Quiet breathing, small head movements, occasional blinks and independent ear flicks |
| Walk | 2.6 s | Four distinct short steps, 80% stance time, 14 mm swing clearance and a small sideways weight shift |
| Forage | 8 s | Slow nose dip and gentle searching head movement, with grounded paws |
| Look | 7 s | Restrained head turn and ear movement |
| Rest | 10 s | Lower relaxed standing stance, slower head movement and breathing; this is not a lying-down pose |

IK contacts are baked into normal bone animation. Foot targets compensate for the sculpt's slightly uneven original soles, and the walking body is lowered enough to reach the full stride without raising support paws. Ear weights stay within the pinnae instead of reaching the similarly high back. The original study walk is in place; future garden integration should match navigation to its contact speed, approximately 0.041 m/s at playback speed 1, and choose the desired walking pace deliberately.

## Review

In the already-running Blender session, choose `Zend STL — wombat`. Idle is enabled there. For other motions, mute the idle NLA track and unmute the desired track, then set the timeline range to its strip. Saved `.blend` files open in a clean rest pose with tracks muted.

From the project root, launch the interactive old/new viewer:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path art_source/animal_studies/preview -- --animal=wombat
```

Choose a motion, drag to orbit, scroll to zoom and press Space to pause. The left model is the frozen game wombat from main at `4fe13f9`; the right model is the supplied sculpt study. Posed heights and lighting are matched. `previews/comparison.png` and the five `*-comparison.gif` files show actual Godot rendering at each clip's authored timing.

## Verification and rebuild

`validation.json` records packed WebP maps, UVs, normalised skin weights, finite poses, loop seams and sampled contact for all five actions. Each supporting paw stays approximately 1 mm above the floor throughout its stance. Actual GLB clips and materials were loaded and rendered in Godot 4.7.2 Compatibility and Forward+; `godot_compatibility.json` and `godot_validation.json` retain those reports, respectively. The preview encoder verifies visible motion in the walk, forage and look captures. `mcp_review.json` records the appended review scene and preserved original context.

Run Blender outside the restricted shell sandbox, as required by the root `AGENTS.md`, and run heavy Blender jobs sequentially:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python art_source/animal_studies/import_sources.py -- /Users/tam/Downloads wombat
/Applications/Blender.app/Contents/MacOS/Blender --background --python art_source/animal_studies/inspect_sources.py -- wombat
/Applications/Blender.app/Contents/MacOS/Blender --background art_source/animal_studies/wombat/prepared.blend --python art_source/animal_studies/build_animals.py -- wombat
/Applications/Blender.app/Contents/MacOS/Blender --background art_source/animal_studies/wombat/wombat_review.blend --python art_source/animal_studies/validate_animals.py -- wombat
/Applications/Godot.app/Contents/MacOS/Godot --rendering-method gl_compatibility --path art_source/animal_studies/preview -- --capture --single --animal=wombat
```

Then run `encode_previews.py wombat` using the bundled Python runtime with Pillow. Do not run the older `refine_export.py` eyelid migration on this study: the builder generates its lids correctly. This is a review study; it has not been selected for production, and visitor dispatch and navigation integration have not changed.
