#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
BLENDER_BIN="${BLENDER_BIN:-/Applications/Blender.app/Contents/MacOS/Blender}"
# Build environment first to supply the shared bark/stone maps, then botanicals.
"$BLENDER_BIN" --background art_source/workshop.blend --python art_source/build_environment.py
"$BLENDER_BIN" --background art_source/workshop.blend --python art_source/build_botanicals.py
"$BLENDER_BIN" --background --python art_source/build_botanical_expansion.py
"$BLENDER_BIN" --background --python art_source/build_botanical_additions.py
"$BLENDER_BIN" --background --python art_source/build_plant_growth.py
"$BLENDER_BIN" --background --python art_source/build_low_grasses.py
"$BLENDER_BIN" --background --python art_source/build_flower_additions.py
"$BLENDER_BIN" --background art_source/workshop.blend --python art_source/build_tools.py
# The MCP-authored overhaul is the authoritative structure/animal library.
"$BLENDER_BIN" --background --python art_source/overhaul/build.py
python3 tests/check_assets.py
