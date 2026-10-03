# Realism direction and material prototypes

The current garden library is an articulated first pass, not a finished realistic
animal library. Rounded lofts and separate rigid body parts remain visible. Higher
polygon counts and detailed albedo cannot by themselves replace anatomical sculpting.

The next quality target is believable animals at the player's normal viewing distance
and convincing close-ups of companions, birds and furniture. Judge it with actual
Godot screenshots and movement, not only a Blender studio render. There is no numerical
measure that establishes a "doubling" of artistic quality.

## What is implemented in this material experiment

Six first-party image-generation assets are saved in `textures/generated/`:

| Image | Purpose |
| --- | --- |
| `cedar-albedo.png` | Timber grain, small knots and silver weathering |
| `limestone-albedo.png` | Mineral colour and fine natural pore variation |
| `short-fur-albedo.png` | Neutral fine mammal coat detail, tinted per species |
| `contour-feathers-albedo.png` | Small overlapping body plumage |
| `feather-vane-albedo.png` | A shaft and barbs mapped along an actual flight feather |
| `fur-card.png` | Alpha-bearing tuft for small curved silhouette strips |

`prompts.json` records the built-in image-generation tool, date and exact prompts.
These are generated colour/opacity assets, not scanned measurements of displacement
or physically calibrated normal/roughness maps. Seamless tiling was requested; inspect
repetition on the actual UVs before making a material authoritative across the library.
The original images retain their resolution and alpha. Blender creates smaller,
species-tinted copies for export; source images stay out of the web build.

The current exported prototypes are **cat, kookaburra and bench**. Their anatomy,
feather UVs and material authoring now use the revised pipeline. The remaining
exported models retain the tested first-pass library; rebuilding them explicitly
with the new helpers is a separate rollout. The raw limestone image is available
for the structure pass, but this three-model experiment does not replace the game's
stone structures or environment.

The cat has a flatter jaw, shaped hind limbs, a fuller tail, recessed eyes and
small laid fur strips attached to its existing joints. The kookaburra has a shaped
skull, neck transition, separate lower bill, eyelids, rounded feather ends and
separate surface textures for body and flight feathers. The bench preserves its
dimensions and iron frame while using the generated wood grain.

Fur cards face outward and sit just above the skin. Pigment follows each sampled
skin polygon, including the cream chest. Godot uses shared alpha-hashed, rough,
softly wrapped materials. The skin supplies the animal's main shadow; hair strips
avoid tiny self-shadows. This is a short-coat approximation, not a simulated groom.
It still needs visual refinement before use as the final realism standard.

Before/after studio renders are preserved as `previews/*-before-realism.png` and
`previews/*-after-realism.png`. `previews/cat-game-realism.png` and the cat/kookaburra
GIFs show the actual compatibility renderer, including animation.

## Recommended complete pass

1. **Species anatomy:** use consistent front, side and three-quarter references.
   Sculpt shoulders, hips, necks, jaws, eyelids and feet. Keep foxes lean, wombats low
   and heavy, and echidnas compact with a genuinely tubular snout. Birds need distinct
   skull/bill proportions and stance. Replace conspicuous separate rigid volumes with
   a connected skin mesh.
2. **Topology and deformation:** retopologize the sculpt around the shoulder, elbow,
   knee, hock, neck and wing joints. Use an armature and skinned weights so joints
   bend continuously. Preserve navigation ownership and existing clip names. Bake
   fine sculpt detail to tangent-space normals rather than exporting the sculpt itself.
3. **Mammal coat:** groom Blender hair guides in anatomical growth directions. Bake
   the dense short coat; use limited cards for cheeks, chest, haunches and tail. Scale
   length/density per species. A smooth short-haired cat and a long-coated dog should
   not share the same silhouette groom.
4. **Bird plumage:** cover the body with fine contour detail and use correctly
   overlapping coverts, secondaries and asymmetric primaries on wings. Paint species
   markings onto deliberate UVs; avoid giant shafts across a torso and repeated comb
   shapes. Fold the wing along the shoulder, elbow and wrist.
5. **Other wildlife:** author insect segmentation, wing venation and compound eyes;
   fine thorax fuzz belongs on bees and moths, not every insect. Fish need overlapping
   scale direction, thin fins and gill detail. Frogs need skin pores and a believable
   jaw/limb silhouette, not mammal fur.
6. **Structures and tools:** use real material scale, grain direction, end grain,
   construction joints, thickness, bevels and localized wear. Add dirt at joints and
   restrained metal patina rather than uniform noise. Preserve all saved coordinates,
   sign text, glazing, bridge clearance and tool grip/hand placement.
7. **Material baking:** use generated images for albedo and author roughness/normal
   information separately in Blender. Bake final complex nodes into the simple
   image-to-Principled layout supported by glTF. Use 1K maps for most assets, higher
   resolution selectively for close-up hero animals, and share common materials.
8. **Natural motion:** match planted foot speed to travel, add weight transfer and
   restrained breathing, stagger head attention, and vary pauses. Birds need a fast
   downstroke, softer recovery and wrist lag. Avoid synchronized loops and constant
   bobbing. Fur need not have expensive real-time simulation.
9. **Lighting:** review under the actual garden sun, shade and evening light with
   sensible roughness. A texture may look detailed in isolation and still look plastic
   under the game renderer. Do not use a studio beauty shot as evidence of game quality.
10. **Performance and acceptance:** compare the old/new assets at the same camera,
    light and distance. Check feet, perches, selection/removal, saved gardens, download
    size and frame rate in both renderers. Add distance LODs and reduce invisible fur
    or feather layers before exceeding the existing 65,000-triangle asset budget.

Blender's hair tools: https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/hair/index.html

Godot's transparency and material options:
https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html

Blender glTF material/export guidance:
https://docs.blender.org/manual/en/latest/addons/import_export/scene_gltf2.html
