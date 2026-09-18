#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
BLENDER_BIN="${BLENDER_BIN:-/Applications/Blender.app/Contents/MacOS/Blender}"
# Build environment first to supply the shared bark/stone maps, then botanicals.
"$BLENDER_BIN" --background art_source/workshop.blend --python art_source/build_environment.py
"$BLENDER_BIN" --background art_source/workshop.blend --python art_source/build_botanicals.py
"$BLENDER_BIN" --background art_source/workshop.blend --python art_source/build_tools.py
"$BLENDER_BIN" --background art_source/workshop.blend --python art_source/build_companions.py
python3 tests/check_assets.py
