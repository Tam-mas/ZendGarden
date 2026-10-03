# Temporary model comparison

Double-click **Compare Models.command** in the project root. The launcher freezes
the current working models and the locally fetched `origin/main` models on first use, then
opens a separate Godot window. It does not change the main game scene.

The initial baseline was verified against GitHub main at
`ca52914172ed22ada94bda93e95f063e1fb69b0c`. It contains 55 entries: companions,
wildlife, shop structures, scenery samples and held tools. Thirty-three entries
have a previous version on main; twenty-two are new additions.

- Each entry defaults to **Keep new**. Click **Keep old** to prefer its main model.
- **Previous / Next**, the arrow keys or the dropdown navigate between entries.
- Drag in either viewport to rotate both cameras. Scroll to zoom; **Reset view**
  restores the starting angle. Both sides retain metre scale with identical camera
  sizes and studio lighting, so changes in actual model size remain visible.
- Select an animation to inspect the new movement. An old model without that
  authored clip remains in its rest pose and says so. **Play** pauses or resumes.
- **1** chooses old; **2** chooses new. New additions disable the old choice.
- Choices save automatically. **Finish review** marks the saved review ready for
  the final model integration. Closing and reopening resumes your selections.

Decisions are recorded in `art_source/overhaul/model_choices.json`, including
the baseline commit, each model's asset path and the frozen new-model hash.
This review tool records preferences; selecting a model does not yet replace
the game's assets. The chosen variants can be integrated once the review is ready.

After a finished review, `python3 tools/model_comparison/apply.py` verifies all
frozen candidate hashes and the original Git/LFS bytes before installing the
chosen runtime GLBs. Selected originals are archived under
`art_source/overhaul/retained_models/`. The Blender exporter honors this policy
even when an individual asset is regenerated through MCP. New source galleries
remain available for further editing. Old scenery selections need environment
integration and are deliberately rejected by the direct-copy applicator.

Reopening preserves both frozen variants, even if main or the working game files
have since changed. To deliberately refresh the new candidates after further
model editing, run `python3 tools/model_comparison/prepare.py --refresh`. A changed
candidate clears its reviewed marker while retaining the previous preference.

Snapshots live under the ignored `captures/model_comparison` directory and are
excluded from Godot imports and web exports. The viewer uses runtime GLTF loading
and the game's fur-material settings. It never opens or changes Blender scenes.

The old shed is extracted directly from main's environment GLB; the old cottage
is a complete representative house extracted from the combined hamlet mesh.
Their coordinates are recentered and their fronts aligned for comparison without
changing their shapes or dimensions. The footbridge reconstructs the exact
procedural boxes and colors from main's `garden.gd/make_bridge`. Selecting old
scenery is a decision about its corresponding environment appearance, rather than
a request to replace the entire terrain.

Run the native visual smoke check (with no other Godot window running):

```sh
python3 tools/model_comparison/prepare.py
/Applications/Godot.app/Contents/MacOS/Godot --path "$PWD" \
  --script tools/model_comparison/viewer.gd -- --smoke-test
```

The check loads every variant, advances all authored clips, restores rest poses
and checks choice navigation. It writes a screenshot to the ignored cache and
does not overwrite the user's real selections.
