# Bed finish textures

Four separate images were made with the built-in image-generation tool: desert
sand, Japanese gravel, pine bark mulch and blue slate chips. The complete prompts
are saved in `prompts.json`; selected originals are beside it. Runtime albedo
textures are 1024-pixel WebP images under `assets/textures/beds`. Small periodic
height derivatives provide subtle normal maps, stored losslessly as WebP.

`tools/prepare_bed_textures.py` rebuilds these images and converts the existing
standalone landscape maps without changing pixels. `compression.json` and
`card-compression.json` record measured encoding savings. The latter records the
initial conversion of all portraits, including the twelve new grass portraits;
subsequent model portrait renders choose the smaller lossless encoding themselves.

The player's supplied `Bk.jpg` is used without compositional edits. Its runtime
copy is `assets/ui/start-garden.webp`; the browser copy is
`web/art/garden-woodland.webp`. Both retain the full 1961 × 990 image at WebP
quality 92. Source pigment maps under `assets/textures/botanical` and `detail`
are embedded into their GLB models and excluded from runtime imports/exports.
They remain available for Blender rebuilds. Normal maps and portrait transparency
are preserved with lossless encoding.
