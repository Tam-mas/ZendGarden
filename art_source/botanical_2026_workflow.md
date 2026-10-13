# Orchard, dry garden and rainforest expansion

Sixty append-only IDs (218–277) extend the original 218 plants. The collection
adds 20 fruit varieties, 20 cacti/succulents and 20 rainforest trees/palms/tree
ferns. Existing Peach remains ID 84; no plant was renamed to make room. Pawpaw
means papaya in this Australian garden. Banana has a fleshy pseudostem and
dragonfruit has triangular climbing stems, despite browsing with fruit trees.

`botanical_2026_data.py` is the modelling brief and stable ID list.
`botanical_2026_geometry.py` authors connected trunks, branches, petioles,
compound leaves, fern pinnae, folded fans, ribbed stems, spines, fleshy leaves,
fruit and young stages. Fruit shapes include banana hands, trunk-borne papaya
and jackfruit, five-ridged starfruit, lychee relief and dragonfruit bracts.
Garden-scale heights are deliberate; they are not wild maximum heights.

The focused repair module rebuilds Pumpkin (49) with ground-resting fruit and
thick peduncles joining the vines. Giant redwood (78) reaches 42 m and Coast
redwood (79) 48 m. Their existing seedling/juvenile meshes retain their small
sizes; their mature foliage/cones share the same revised attachment space.
These three explicit revisions supersede their historical full-pass envelope
checks. All other original plant assets retain the previous baseline contract.

## Rebuild and review

Use a separate Blender background process with the approved OS execution access
described in AGENTS.md. Never run exports concurrently or modify the interactive
scene. For each batch 0 through 6, run:

```
/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python art_source/build_botanical_2026.py -- --batch 0
```

Batch 0 holds the three repairs; batches 1–6 each hold ten additions. Each
compressed `botanical_2026_XX.blend` contains the mature and growth meshes and
packed textures. The exporter emits the 126 GLBs and measured provenance in
`botanical_2026_manifest.json`, and refreshes general asset/growth manifests and
`scripts/plant_profiles.gd`. The main `rebuild.sh` runs this pass after the legacy
and full-library builders. `--audit-only` validates geometry without writing
assets. Mature meshes have a 200,000-triangle limit and combined growth organs
an 18,000-triangle limit, matching the previous library.

New images were generated with the built-in image tool by the requested Luna
texture subagent. Exact prompts are in `botanical_2026_texture_prompts.json`.
Original 1254px tissue PNGs stay under `assets/textures/botanical_2026/`.
Blender creates packed 256px tinted derivatives with existing normal/roughness
maps. Succulent surfaces remain rigid. UV2 and vertex-colour channels preserve
local bud/fruit attachments; they never supply visible tint. GLB imports retain
`gltf/embedded_image_handling=2` so textures stay compressed in the web export.

Import with Godot, then render portraits with `render_plant_cards.gd -- --ids=…`.
The card camera's far plane scales with bounds to accommodate the tall redwoods.
The dedicated `review_botanical_2026.gd` produces an isolated review gallery and
growth strips without loading or writing a player's garden.

Verification: `check_botanical_2026.py` checks all new exports, source coverage,
heights, three independent stages, local attachments and the pumpkin's ground
contact. General plant, growth and full-library checks remain applicable.
`plant_art_full.gd` exercises 278 species through five game growth states and
continues the saved-cultivar checks. The read-only Blender source validator has
`--botanical-2026-only` for the seven new editable libraries.

## Morphology references

The modelling briefs use plant descriptions and botanical illustrations as
shape references, not downloaded source textures or copied meshes:

- [NParks: mango](https://www.nparks.gov.sg/florafaunaweb/flora/3/0/3013): long,
  narrow simple blades and a branching fruit-tree canopy.
- [UF/IFAS: papaya](https://ask.ifas.ufl.edu/publication/FP106): palmately lobed
  leaves and fruit at the leaf axils close to the trunk.
- [NParks: dragonfruit](https://www.nparks.gov.sg/florafaunaweb/flora/1/4/1419):
  climbing cactus stems and fruit with conspicuous leafy bracts.
- [NParks fruit-tree survey](https://www.nparks.gov.sg/-/media/nparks-real-content/learning/teaching-and-learning-resources/worksheets/lower-primary/fruit-tree-survey.pdf):
  tropical fruit identities and banana/papaya/breadfruit distinctions.
- [RHS: soft tree fern](https://www.rhs.org.uk/plants/5794/dicksonia-antarctica/details/)
  and [Kew: Dicksonia antarctica](https://powo.science.kew.org/taxon/urn%3Alsid%3Aipni.org%3Anames%3A17082540-1/general-information):
  fibrous trunks with divided frond crowns, distinct from palms.
- [NParks: golden chicken fern](https://www.nparks.gov.sg/florafaunaweb/flora/3/8/3816):
  low golden rhizome and broad arching fronds.
- [RHS: aloes](https://www.rhs.org.uk/plants/aloe?type=0) and
  [RHS: cacti and succulents](https://www.rhs.org.uk/plants/types/cacti-succulents/houseplants/growing-guide):
  fleshy rosettes and the contrasting flattened/trailing rainforest cacti.
- [ANBG: Moreton Bay fig](https://anbg.gov.au/stamps/stamp-ficus-macrophylla-2025.html):
  a broad rainforest crown with a substantial buttressed trunk.

These game meshes simplify small-scale anatomy for browser rendering; the
growth intervals follow garden gameplay rather than real-world elapsed years.
