# Realism and game-ready material pass

The next quality target is believable animals at the player's normal viewing distance
and convincing close-ups of companions, birds and furniture. Judge it with actual
Godot screenshots and movement, not only a Blender studio render. There is no numerical
measure that establishes a "doubling" of artistic quality.

## Implemented library pass

The completed model comparison keeps the original cat, dog, bee, frog and rabbit
from main `ca52914` in the game, and the new versions of the other 50 models.
`model_choices.json` records the review. Their original GLBs and checksums are
preserved in `retained_models/`; individual exports honor these preferences.
The source libraries still contain all newly authored candidates described below.
Runtime checks verify the retained original bytes and their procedural movement,
while the remaining upgraded mammals/birds must pass the weighted-skin checks.

Seven image-generation sources are saved in `textures/generated/`: cedar, limestone,
short fur, contour plumage, flight-feather vanes and two alpha-bearing hair cutouts.
`prompts.json` records the tool, date and exact prompts. These are generated colour
and opacity assets; the procedural micro-normal and roughness maps are authored
separately. They are not scans or physically calibrated displacement measurements.
Source images are excluded from the game build, and each GLB embeds its own maps.

All eight mammals now use a connected, weighted skin mesh and a real armature.
The existing motion controls remain available to gameplay; their named clips are
baked to the bones. Weighted hair cards follow the same skeleton. Coats range from
short cat, wombat and echidna hair to longer dog and fox tufts. Feet have short hair
on top and clear soles. The rabbit has fuller haunches, the wombat a broader barrel,
and the dog and fox narrower skulls. Wombat walking uses staggered four-foot steps.

All six birds have a connected, weighted head/neck/body surface, contour-plumage
maps, individually shaped wing/tail feathers and separate wrist controls. The
kookaburra eye stripe is narrow and tapered rather than a heavy band. Birds retain
flight, folded perch, drinking, bathing and foraging clips. Bees and the emperor gum
moth get small thorax tufts; other insects keep cuticle and wing surfaces.

All 21 furnishings, three scenery models, the landscape's buildings/walls and five
held tools receive the revised material pipeline. Timber UVs follow each part's long
axis at a consistent physical grain scale. Limestone and plaster use a metre-scaled
projection; tool handles use timber grain, with subtle brushed metal and rubber
surfaces. Tool geometry, hand placement and the watering-can handle are preserved.

Godot gives fur shared alpha-hashed, rough, softly wrapped materials. The body
supplies the main shadow; hair strips avoid tiny dotted self-shadows. This is a
short-coat approximation, not simulated strands. The skin comes from connected
remeshed anatomical volumes with smoothed weights, rather than hand-retopologized
sculpts. The result is a more detailed stylised library, not photorealistic wildlife.

The source gallery libraries remain editable. Studio review sheets import the actual
exported GLBs. Motion previews come from Godot's imported clips. Asset tests require
weighted skins for all mammals and birds, actual alpha in hair PNGs, resolved animation
paths, agreement between neutral bones and inverse binds as well as animated skin bones and controls, grounded feet, and the existing
65,000-triangle budget. Visitor behaviours and saved furnishing kind names remain
compatible.

## Further art refinement

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
