# Mountain-stream divide

The 18.5 m × 120 m joining strip is now a protected ravine, with a meandering
roughly four-metre channel and a bed three to five metres below its banks.
Neither the original plot centres nor the ten habitat centres moved.

Three 18.5 m stone bridges cross at world z = 6, −48 and −102. Each has a
2.8 m clear deck, a shallow 0.72 m crown, an open masonry arch barrel,
individually fitted voussoirs and spandrel courses, and 0.95 m parapets.
The ends remain open to a 1.8 m path along the original garden bank.
Two new two-metre approaches join the main trail via the orchard/glasshouse
boundary and the graded northern edge of Alpine Lookout. The southern
approach follows the existing Reedwater bend. The bridge decks replace,
rather than overlap, the connecting-trail footprint in the ravine.

## Reproduction

- `python3 art_source/ravine_profile.py` writes the quarter-metre ground lattice
  and stream centre, level and width samples to `assets/areas/ravine.json`.
- `python3 art_source/build_connecting_trail.py` writes all three shared routes
  and their disjoint path footprints. Habitat source clearance uses these routes.
- Run Blender sequentially with `--background --python-exit-code 1 --python
  art_source/build_ravine.py`. The packed source is
  `art_source/overhaul/AlpineRavine.blend`; the runtime model is
  `assets/environment/alpine_ravine.glb`. Existing ImageGen stone textures are
  reused with consistent metre-scale UVs. The original interactive Blender scene
  and preferences are untouched.
- Rebuild habitats 4 and 8 with `build_distinct_areas.py -- 4` and `-- 8` when
  their approach routes or terrain grading change.

The runtime uses the same sampled bed for its terrain mesh and collision.
Deck heights use the same arch equation as Blender. Water moves from north to
south over four short cascades and continues over the southern escarpment to
the lake. Ten local stream meshes and one outlet fall use the existing bounded
water clock, rain disturbance and reduced-motion setting. Rocks are batched by
reach; existing detailed plant meshes provide instanced ferns, sedges, grasses
and small hawthorn shrubs. The source manifest records geometry and file size.

## Existing gardens

Former slope edits remain in the save but are inactive inside the protected
ravine. Player positions on a bridge restore to its deck; other positions in the
channel move to a bank. Loose plants in the old strip retain their full growth
and care records in Stored plants. Furnishings search for a clear patch of open
dry ground and retain IDs, work state and contained plants. A fully occupied
garden falls back to the eastern bank, keeping every furnishing available.
The recovery is idempotent and reports any moved contents in the game.
Planting, building, moving furniture, raking and sculpting cannot fill the stream
or obstruct the bank trail. Existing garden planting milestones still apply.

## Review

`--land-test` exercises bridge floors, side parapets, both-way player traversal,
all three approach routes, bank paths, companion routing, old saves, and water.
`--land-test --land-review` captures the ravine at eighteen viewpoints/conditions;
add `--forward-review` when using Forward+. Captures are under
`captures/alpine-ravine/`. The shared footprint, all ten paving networks,
habitat gameplay and packed Blender libraries have independent checks.

## Finished boundaries and landings

`GardenBoundary` builds low, capped fieldstone walls around both gardens and
along the river banks, leaving the three bridge mouths open. Its legacy outline
moves when more original garden rows appear; new walls and the growing garden’s rock foundations use the existing terrain
editing system and preserve the stone colours when split into local chunks.
The old rear fence is removed completely, including the stones that blocked the
west-bank trail at z = −24.5.

The Blender escarpment now surrounds the whole extension, including the eastern
edge, both ends and the source cleft. Outward-facing rock shelves, embedded
outcrops and a sealed underside reach below the lake. The original meadow is
clipped at the western seam, and its existing slope meets the new cliff without
crossing surfaces. The outlet waterfall follows the same rock profile.

Bridge landings have continuous stone bases and share the deck height across
their full width. A wider southern apron reaches the original garden path, clear
of the relocated birch; eastern aprons extend into the approach bends. Meadow
grass excludes the new paving. Saved sculpt records remain intact, with graded
transitions into the fixed southern bridge foundation and outer rock rims.

`tests/garden_boundary.gd` checks 993 starting-garden wall samples and 1,002
expanded-garden wall samples, exposed cliff faces, the former wall blockage,
landing seams and the route into later garden rows. `--land-test` walks the
entire 108-metre bank route both ways and each lane of the southern landing.

## Stream composition and quiet water

The banks now use groups of bedded granite with bevelled shoulders, satellite
stones and occasional shingle fans. Four asymmetric stone shelves frame the
existing cascades without closing the central channel. Low blue grasses near
the source gradually give way to sedge and maidenhair drifts downstream;
occasional hawthorn softens the upper bank. Bridge viewpoints and both bank
trails remain open. Capped masonry end piers finish all three parapets with
2.68 metres between their caps, outside the protected 2.44-metre walking lane.

The water keeps its sampled downhill surface normal, with gentle flow through
the pools and broken foam settling below each cascade. The outlet contracts
just after the lip before opening into irregular spray threads. Water, rain
ripples and reduced motion continue to use the shared water controller; no
extra water surfaces, save fields or terrain profiles are introduced.

`python3 tests/check_ravine.py` checks the actual shipped GLB for embedded
textures, finite geometry, its detail budget, planted-bank clearance and clear
bridge lanes. The current export has 89,446 triangles and 344 instanced
botanical anchors. Rebuilding through `build_ravine.build()` replaces only
generated ravine roots and restores the interactive scene and selection even
if export fails.

Rock footings follow the sampled ground at each lower vertex, so downhill
edges remain embedded even on the steepest banks. Rounded outlet stones retain
their upper shoulders with the same buried footing treatment. Run
`python3 tests/check_ravine_grounding.py` to check contact and face winding
across both banks without starting Blender; the outer cliff foundations are
unchanged.
