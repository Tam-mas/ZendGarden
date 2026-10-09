# Dense gardens

## 9 October 2026: targeting and habitat detail

Implemented review options 1, 2 and 4. Container occupancy now uses a garden-owned
lookup invalidated alongside the spatial index. Ray targeting rejects distant
and off-ray pockets before checking occupancy, with allowance for the elevated
plant target. No saved fields change.

Habitat batches retain complete imported organ meshes rather than reconstructing
surfaces without LODs. Mesh data, materials, shadow meshes and all imported LOD
buffers are preserved. In Auto, habitat LOD bias is 0.5 and small-plant shadows
are omitted only when the camera is more than four metres from the whole batch's
padded bounds. Standard restores habitat LOD bias 1 and authored shadows. Distant
forest bias is corrected from 2 to 0.5; lower values simplify earlier. No source
models, texture sizes, render resolution or cell partitioning change.

`tests/garden_performance.gd` compares 1,248 rays against the original targeting
rules, including rotated/elevated pockets, occupied and empty slots, reach edges
and ground obstruction. It checks lookup invalidation and verifies exact imported
surface data, LOD and material preservation, plus shadow restoration and moved
bounds. It runs headlessly in both the local suite and browser-build CI.

A native isolated test with 1,739 plants and 120 distant pockets takes about
0.09 ms per targeting call, compared with about 90 ms before this change. With
100 and 5,000 plants the new distant-pocket path remains around 0.08–0.09 ms.
These are operation timings, not whole-game frame rates.

Two matched full-world Compatibility views on an RTX 5070 Ti compare current
Auto with a runtime reconstruction of the old habitat meshes without LODs,
full habitat shadows and forest bias 2:

| View | Old detail primitive counter | Current Auto | Current Standard |
| --- | ---: | ---: | ---: |
| Kitchen entrance | 83,401,430 | 6,629,590 | 7,128,102 |
| Distant kitchen | 60,923,563 | 5,338,147 | 5,667,559 |

These engine counters include render passes; they are not counts of unique
asset triangles or browser FPS. Near/far screenshots were inspected for visible
planting and shadow changes. Compatibility workshop targeting/save checks and
dense-garden checks pass in both Compatibility and Forward+. The workshop test requires a real display for its
mouse-capture assertions. Save files, update history, atlas and breeding tests
also pass. A current browser walking-route measurement is still needed: the
older photo-mode benchmark below skips ordinary hover targeting and walking.

## 4 October 2026: earlier browser baseline


The supplied day-77 garden contains 1,739 planted specimens, 55 structures and
12 unlocked areas. Its JSON file is approximately 399 KB. The personal save is
not committed to the repository; all profiling loads disposable copies.

## Chrome measurements

The same save and two fixed camera positions were measured in the same Chrome
window on this Mac's Apple M1. Each view warms up for 20 frames and records 60
frames. The game clock is held at the saved time, and new visitor spawning is
disabled in both runs. The main baseline is commit
`f67280c8895be83b77ea49ce8147ba69bf83f4dc`.

| View | Current main median / p95 | Updated Auto median / p95 | Approximate FPS before → after | Draw calls before → after |
| --- | --- | --- | --- | --- |
| Beginning bed, near the pergola | 56.6 / 58.8 ms | 35.6 / 39.0 ms | 17.7 → 28.1 | 7,268 → 2,191 |
| Sunrise terrace, overlooking the full garden | 158.6 / 167.3 ms | 49.0 / 54.0 ms | 6.3 → 20.4 | 28,170 → 4,716 |

The garden script's median work fell from 4.6–4.9 ms to 1.2 ms per frame.
FPS varies with hardware, browser window size and other applications. These
measurements compare the default Auto behavior: the updated large-garden
profile uses 85% 3D resolution, earlier distant mesh detail changes and
shorter-range small-plant shadows. Explicit resolution choices are respected.
Auto removes expensive multisample antialiasing; Forward+ can use FXAA instead.
Standard graphics retains full plant shadows, 2× MSAA and the original 90 m
shadow distance. Mobile keeps its existing automatic 70% resolution and disabled
sun shadows.

## Implementation

- Group repeated visible plant organs by shared mesh/material and 6 m world
  cells. The same models, textures, saved shape variations and growth stages
  remain in use. Cell boundaries allow culling away from the current view.
- Send each plant's shape through MultiMesh custom data, instead of duplicating
  every surface's material in WebGL. Keep individually outlined selections out
  of their batch while selected; return them afterward.
- Group the fixed border plants too, and update instance transforms during
  growth/pruning tweens. A trim within the same stage updates affected instances;
  stage changes, placement, movement and removal rebuild the groups.
- Use a spatial index for targeting, overlapping layers and canopy shade. Read
  each plant's growth rate once per morning. Leaf wind stays in the shader.
- Allocate the seed marker's meshes only when the plant needs a marker. Reuse
  its small meshes, and restore loaded plant sizes directly without startup
  growth tweens.
- Replace the generic climber spheres with small curved blossoms, compound
  leaves and thin stems following the actual authored post coordinates. Support
  growth updates on care, structure and terrain changes, rather than searching
  for supports every frame. New flower geometry reuses existing botanical maps.

## Reproducing the profile

Native Compatibility rendering (a separate cache save is written; the supplied
file and active player garden are untouched):

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . --rendering-method gl_compatibility --always-on-top --script tools/benchmark_garden.gd -- --garden-save=/absolute/save.json --report=/tmp/garden-profile.json --capture=/tmp/garden-profile
```

Chrome, using a local export containing the private fixture only in ignored
`build/web/`:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot python3 tools/build_dense_benchmark.py /absolute/save.json
python3 -m http.server 8941 --bind 127.0.0.1 --directory build/web
```

Open `http://127.0.0.1:8941/` in Chrome and press Enter the garden. The page and
console report the results. Add `--baseline-ref <local-commit>` to the builder
for the original runtime. The builder restores the source scripts and normal
entry scene in `finally`. Do not publish the benchmark export; rebuild the
normal game with `tools/build_web.py` afterward.

`tests/dense_garden.gd` requires a real Compatibility or Forward+ renderer:
headless dummy rendering does not retain MultiMesh instance readback data.
The standard test runner checks both renderers, including selection, trimming,
growth/harvest, movement/removal, rotated supports and graphics settings.

## Live download size

Read-only measurements of zend.garden on 4 October 2026:

- Compressed pack chunks: 674,710,789 bytes (674.7 MB).
- Engine WASM: 10,030,268 bytes (10.0 MB).
- Engine scripts, intro artwork and page resources: approximately 0.8 MB.
- First-visit transfer: approximately 685.5 MB (653.8 MiB).
- Unpacked game pack: 693,225,728 bytes (693.2 MB / 661.1 MiB).

Subsequent visits can reuse cached files. The exported pack size is different
from the save's size and from total browser memory consumption. Runtime frame
optimizations do not materially reduce this download. The source Blender files
and this document are excluded from web exports.

## Botanical basis

The pictured lilac rows came from the generic climbing-support decoration used
by Clematis (and other climbers), rather than a real seed-pod model. Clematis now
uses pointed, outward-facing flowers with fine cream stamens; Sweet pea uses
the existing banner, wings and folded keel petal forms. Pea has small pale
flowers, Cucumber has small yellow flowers, and jasmine has white stars. Flower
visibility follows the plant's blooming stage.

References: [RHS Clematis guide](https://www.rhs.org.uk/plants/clematis/growing-guide),
[RHS sweet peas](https://www.rhs.org.uk/plants/lathyrus/sweet-peas).
