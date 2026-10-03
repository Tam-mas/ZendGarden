# Botanical additions validation — 3 October 2026

- Added 30 entries, IDs 106–135: ten grasses and twenty cacti/succulents. All original 106 source rows and ideal growing-day values match the prior Git revision. No save-schema change.
- Mature catalogue: 136 models, 6,419,334 triangles; the 30 additions use 644,762 triangles. Largest remains the existing Cherry blossom at 195,816. All meshes have finite coordinates, UVs, embedded colour/normal/roughness maps, and stay within individual and library budgets.
- Growth catalogue: 136 models and 781,296 triangles, including 210,824 for the additions. All have Seedling, Juvenile and Buds groups. Early succulent bodies retain their species-specific organs and smaller proportions.
- Sweet pea and Clematis retain their IDs and pass the existing placement-envelope comparison against their previous GLBs. New flowers use opaque surfaces and explicitly triangulated curved petals; large portraits were reviewed in native Metal and OpenGL Compatibility.
- Thirty new and two revised 192-pixel portraits are rendered from the game models. Large native and Compatibility portraits were inspected for joined pads, fine spines, optical-window leaves, fleshy rosettes, flower proportions and revised climber petals. Review sheets can be generated with `tools/compose_additions_reviews.py`; images are local ignored captures.
- `tests/check_blender_sources.py`: all nine source libraries pass, including 64 meshes in `botanical_additions.blend` and 408 in `plant_growth.blend`, with no missing external images. The check loads source files read-only in an isolated Blender process.
- `zsh tests/run.sh`: pass. Includes model, growth, planting-preview, botanical-category and rigid-organ checks, native and Compatibility game UI, six desktop/touch resolutions, tutorial, leisure, save compatibility and the broader gardening smoke tests.
- The succulent category shows all 20 cards and retains the compact ornate menu at 1280×800, 1024×768, 900×600, 320×568, 390×844 and 844×390. Search finds both common and botanical names.
- Local browser export: 501.5 MiB uncompressed game data across 26 compressed pack pieces; package-integrity and security checks pass. No individual hosted file exceeds the existing 25 MiB limit.
- Actual Chrome/Godot tests pass for imported v1 and v2 gardens, failed IndexedDB mount preservation and a resumed welcome lesson. The v2 fixtures include new grass ID 106, cactus ID 116 and living-stone ID 135; all survive the browser save after advancing the lesson.

These checks exercise the local build and automated renderers. No physical phone performance measurement or website deployment is included.
