# Running and developing Zend Garden

This guide covers running the project from source, checking changes and editing its art. For an introduction, see [the main README](../README.md).

### Requirements

- [Godot 4](https://godotengine.org/download/), standard edition. The project is configured for Godot 4.7 and has been tested with **Godot 4.7.2**.
- [Git](https://git-scm.com/downloads) and [Git LFS](https://git-lfs.com/) to download the game and its 3D assets.
- A computer that supports Godot's **Forward+** renderer.

The game has been tested on an Apple silicon Mac. Windows and Linux have not yet been verified. **Blender is not required to play**; the repository includes the exported models used by the game.

### Download and launch

Install Git and Git LFS, then run:

```sh
git lfs install
git clone https://github.com/Tam-mas/ZendGarden.git
cd ZendGarden
git lfs pull
```

The models and editable art files use Git LFS and add a few hundred megabytes to the download. Use the clone instructions above: a GitHub ZIP download may contain asset pointers instead of the models themselves.

1. Open Godot's Project Manager and choose **Import**.
2. Select `project.godot` from the downloaded folder.
3. Open the project and allow the initial asset import to finish.
4. Press **F5** to play.

On macOS, you can also use `Play Zend Garden.command` if Godot is installed as `/Applications/Godot.app`.

### Project layout

| Location | Contents |
| --- | --- |
| `project.godot` and `main.tscn` | Godot project and starting scene |
| `scripts/` | Gameplay, interface, terrain, weather, and companions |
| `shaders/` | Rendering effects |
| `assets/` | Models, textures, and other runtime assets |
| `art_source/` | Editable Blender files, generation scripts, and botanical references |
| `tests/` | Asset checks and game smoke tests |

### Checking changes

The test runner requires **zsh**, **Python 3**, **ripgrep**, and Godot. On macOS with Godot in `/Applications/Godot.app`, run:

```sh
zsh tests/run.sh
```

For another Godot installation, provide the executable path:

```sh
GODOT_BIN="/path/to/godot" zsh tests/run.sh
```

The runner checks assets, imports the project, and runs wildlife and gameplay checks. The gameplay test opens a visible game window and uses a separate test save. Keep the window visible while it runs.

### Working on plant models

The game uses exported `.glb` models. Editing or regenerating the source art requires Blender; the existing workflow has been tested with Blender 5.2.1. To rebuild the generated assets:

```sh
BLENDER_BIN="/path/to/blender" zsh art_source/rebuild.sh
```

On macOS, the script defaults to Blender in `/Applications/Blender.app`. Run heavy exports sequentially, then open Godot to import the updated assets. See the [botanical references](../art_source/botanical_references.md) for the plant forms that guide the stylized models.

### Inspecting shop models

Every shop item has an exported model in **`assets/shop/`**:

- Open a `.tscn` in Godot to inspect the complete scene, including lights and sign lettering.
- Import the matching `.glb` into Blender or a glTF viewer to inspect its geometry and materials. Sign lettering is a Godot label and is preserved in the `.tscn`, rather than the GLB.
- Examples: `greenhouse.tscn`, `bath.tscn`, `stone.tscn`, and their `.glb` counterparts.

The game loads the Blender models directly from `assets/shop/`, with editable sources in `art_source/shop_library.blend`. Animals use `art_source/companions.blend` and `art_source/wildlife_library.blend`. These models include embedded colour, normal and roughness maps; Godot keeps the embedded textures compressed and generates mesh LODs on import.

Rebuild the models with Blender, then refresh the Godot inspection scenes:

```sh
blender --background art_source/workshop.blend --python art_source/build_shop.py
blender --background art_source/workshop.blend --python art_source/build_companions.py
blender --background art_source/workshop.blend --python art_source/build_wildlife.py
godot --headless --path . --editor --import
godot --headless --path . --script tools/export_shop_models.gd
```

The inspection-scene command preserves the Blender GLBs. See [the detailed asset workflow](../art_source/detail/README.md) for model coverage, animation contracts and visual review commands.

Bird-bath behaviour lives in `scripts/bath_life.gd`. Bath visitors leave at night, and calls fade with distance.

### Music and ambience

The four areas have original synthesized themes with different melodies, spacing and instrument envelopes:

| Area | Tune | Sound and mood |
| --- | --- | --- |
| The beginning | Room to Grow | Rounded felt-style keys; a small, welcoming melody with pauses |
| Willow water | Still Ripples | Soft wooden/nylon-style plucks; unhurried phrases over water texture |
| Fern hollow | Under the Ferns | Low flute-like swells; sparse, sheltered and airy |
| Sunrise terrace | Morning Air | Warm sustained tones; slowly opening phrases with long releases |

Meadow and wildflower gardens use Room to Grow, orchards use Morning Air, and later woodland gardens use Under the Ferns. All themes use the same suspended D/E/G/A/B pitch palette at A4=440 Hz, with a quiet D/A foundation. They have no percussion, detuned oscillators, metallic partials or pitch bends. The former tracks transposed one repeated motif into different keys while keeping a C/G accompaniment; the terrace's F-sharp against that low C was a likely source of the distracting pitch tension.

Music loops are exactly 64 seconds. Notes and their quiet room tails wrap around the phrase boundary instead of splicing away a second of music. The former renderer reduced 32-second phrases to 31 seconds. Nature loops are exactly 32 seconds, with circular noise, quieter night insects and separately timed bird calls. Waterside ambience uses noise rather than a pitched water tone. Sources remain mono, 16-bit, 22.05 kHz PCM with forward looping, avoiding extra browser decoding requirements.

Moving between areas crossfades the music with a 3.5-second smoothing time constant (about 8 seconds to reach 90% of the target gain). A 1.5-metre advantage in distance to the new area's centre is required before switching, preventing repeated changes at an area boundary. Music softens at night and in rain. Music and nature settings remain independent; the existing master volume still applies. Zero Music volume immediately mutes the dedicated Music bus and sets its players to zero linear gain. The loops keep advancing silently, preserving phrase alignment when music resumes; nature and bird-bath audio do not use that bus.

Regenerate all ten sources with `python3 tools/build_audio.py`; only Python's standard library is required. Then import in Godot. `python3 tests/check_audio.py` checks exact phrase lengths, actual rendered fundamentals, accompaniment key, level balance, loop boundaries and import settings. `tests/soundscape.gd` checks area selection, boundary stability, forward looping, unmodified playback pitch, crossfades, weather balance and independent mute controls. The runtime check is included in `tests/run.sh`. These checks validate rendering and playback behaviour; musical feel still needs a listening review on headphones and speakers.

### Player update history and version

`scripts/player_updates.gd` holds a curated history of meaningful player-visible changes. Add a short entry at the top of `GardenUpdates.RELEASES` using the next integer version and a player-facing date, title and note. The latest entry determines `CURRENT_VERSION`, shown in Settings and What’s new. Keep numbers stable and leave invisible engineering work in the technical `CHANGELOG.md`.

Returning players see only entries newer than `settings.updates_seen`. Close, Done/Back to the garden, or Escape stores the current version with the existing garden save. Settings → What’s new reopens the full history. New visitors finish the welcome walk without receiving historical notifications. This preference does not change the save schema version or reset existing gardens. `tests/player_updates.gd` covers history selection, saved dismissal, reopening and viewport bounds; `tests/experience.gd` exercises the actual Settings buttons and music slider.

### Working on the background mountains

The surrounding terrain and outer ridge chains are editable in `art_source/lake_garden.blend`. Their deterministic relief is defined in `art_source/mountain_forms.py`; `build_environment.py` places the woodland, fits the shoreline to the terrain and exports the environment. Godot applies the world-aligned rock colour/normal maps, slope-dependent vegetation, scree and high-altitude snow in `shaders/mountain.gdshader`.

Rebuild only the environment, then import and review all four directions:

```sh
"/Applications/Blender.app/Contents/MacOS/Blender" --background art_source/workshop.blend --python art_source/build_environment.py
"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . --editor --import
"/Applications/Godot.app/Contents/MacOS/Godot" --path . --script tools/preview_mountains.gd
python3 tests/check_mountains.py
```

The preview writes `captures/mountains/after-{west,north,east,south}.png` without loading a player save. Add `--rendering-method gl_compatibility` before `--script` to check the compatibility renderer. For a matched comparison, put the earlier exported environment at `captures/mountains/before.glb` and its shader at `captures/mountains/before.gdshader`, then append `-- --compare`. Add `--benchmark` after that to measure 120 frames per direction for each version under the same running conditions. `tests/check_mountains.py --baseline captures/mountains/before.glb` also checks that the playable garden geometry matches that baseline. The terrain check is included in `tests/run.sh`.

### Detailed plant models and comparisons

All 106 catalogue plants use detailed botanical models, with curved leaves, refined branching, layered petals, flower centres, fruit details and embedded colour/normal/roughness textures. Editable sources are `art_source/botanical_library.blend` (original 60) and `art_source/botanical_expansion.blend` (46 additions). See [the plant detail workflow](../art_source/plant_detail_workflow.md) for rebuilding, matched before-and-after renders and asset/runtime validation. Catalogue IDs and existing growth, pruning and harvesting behaviour are retained.

### Reviewing background woodland

The landscape includes 28,869 background trees, with the added mature stands
placed using the same horizontal/vertical scale as the game. Tree crowns are
batched by location, use solid pigments without unused UV buffers, and fade
into clearings and a varied treeline. The independent woodland random seed
preserves the original scenery and hamlet positions.

For this pass, the matched baseline lives locally in `captures/woodland/`.
Run `tools/preview_mountains.gd` with `-- --woodland --compare --benchmark`
to render all four directions and compare frame rates. The source counts and
triangle totals are recorded in `art_source/landscape_validation.json`.
