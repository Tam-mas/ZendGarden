# Area refinement surface assets

## 8 October 2026: garden realism pass

Generated with the built-in ImageGen tool. Both source colour images are kept
unchanged. `area_realism.py` derives periodic 512px normal maps in Blender and
packs the images into all consuming GLBs and source libraries. The common trail
uses copies of the sandstone and its normal in `assets/textures/garden-path/`.

### `split-sandstone.png`

> Use case: photorealistic-natural. Asset type: seamless physically based game material, diffuse albedo only. Create a square orthographic top-down macro photograph of one continuous expanse of weathered warm grey sandstone, about 1.2 metres across. Subtle greige and muted taupe mineral clouds, very fine quartz grit, shallow natural split-face sediment lines, sparse tiny charcoal pores and tiny ochre flecks. Real garden paving stone with believable quiet granular texture, matte and softly worn. Flat neutral diffuse lighting across the entire image, no directional lighting, no highlights, no cast shadows, no vignette. Edge-to-edge surface, seamless tiling on all four sides. There must be NO tile boundaries, NO grout, NO brick pattern, NO objects, NO plants, NO writing, no perspective. Keep low contrast overall, fairly even mid-grey/beige albedo. This image will be mapped onto individually modelled garden flagstones so only the mineral surface is needed.

### `garden-wall-brick.png`

> Use case: photorealistic-natural. Asset type: seamless PBR base color texture for a realistic old garden brick wall. Square image, orthographic front view, exact flat diffuse albedo with no illumination gradients, shadows, specular or perspective. Entire image filled with weathered handmade English garden wall clay bricks in staggered running bond. About eight horizontal courses across the square, bricks twice as long as tall. Narrow warm grey lime mortar, irregular softly worn brick edges, rich but restrained muted russet terracotta, brown-red and small desaturated ochre variations between bricks, tiny pores and chipped clay surface. No large missing pieces, no cracks across wall, no moss/vegetation, no writing, no frame. Tile seamlessly left-right and top-bottom, steady spatial scale. Quiet realistic garden material, not glossy and not exaggerated orange. This is a material swatch for game geometry, not a scene.

## Earlier bark pass

`weathered-bark.png` was generated with the built-in ImageGen tool on 6 October 2026. The original colour bitmap is retained unchanged. Blender derives a packed microrelief normal map from its luminance. Existing Garden loam and other bed surfaces are reused for changeable soil.

Prompt:

> Use case: photorealistic-natural. Asset type: physically based 3D game surface texture, seamless square albedo bitmap. Primary request: a close, flat orthographic scan of weathered fallen eucalyptus bark, richly detailed grey-brown and warm umber fibrous bark with narrow long branching fissures and small curled flakes, subtle pale lichen flecks. Bark fibres and cracks run vertically across the image. Even diffuse neutral lighting, no directionally cast shadows, no perspective, no visible log silhouette, no background, no text, no vignette, no border. It must tile naturally on a cylindrical woodland log and a soft tree fern trunk. Organic restrained colour variation, natural garden colour palette, detailed tactile small-scale bark, avoid black gashes and cartoon shapes.
