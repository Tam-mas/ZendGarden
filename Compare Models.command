#!/bin/zsh
set -e
cd -- "${0:A:h}"
python3 tools/model_comparison/prepare.py
exec /Applications/Godot.app/Contents/MacOS/Godot --path "$PWD" --script tools/model_comparison/viewer.gd
