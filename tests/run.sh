#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
python3 tests/check_assets.py
python3 tests/check_greenhouse.py
python3 tests/check_mountains.py
python3 tests/check_plants.py
python3 tests/check_audio.py
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
logfile="$(mktemp -t zend-garden-test)"
import_log="$(mktemp -t zend-garden-import)"
"$GODOT_BIN" --headless --path "$PWD" --editor --import > "$import_log" 2>&1 || { cat "$import_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$import_log"; then
  cat "$import_log"
  exit 1
fi
audio_log="$(mktemp -t zend-garden-audio)"
"$GODOT_BIN" --headless --path "$PWD" --script tests/soundscape.gd > "$audio_log" 2>&1 || { cat "$audio_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$audio_log" || ! rg -Fq 'SOUNDSCAPE_RESULT: []' "$audio_log"; then
  cat "$audio_log"
  exit 1
fi
mouse_log="$(mktemp -t zend-garden-mouse)"
updates_log="$(mktemp -t zend-garden-updates)"
"$GODOT_BIN" --headless --path "$PWD" --script tests/player_updates.gd > "$updates_log" 2>&1 || { cat "$updates_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$updates_log" || ! rg -Fq 'PLAYER_UPDATES_RESULT: []' "$updates_log"; then
  cat "$updates_log"
  exit 1
fi
"$GODOT_BIN" --headless --path "$PWD" --script tests/mouse_look.gd > "$mouse_log" 2>&1 || { cat "$mouse_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$mouse_log" || ! rg -Fq 'MOUSE_LOOK_RESULT: []' "$mouse_log"; then
  cat "$mouse_log"
  exit 1
fi
detail_log="$(mktemp -t zend-garden-detail)"
"$GODOT_BIN" --headless --path "$PWD" --script tests/detail_models.gd > "$detail_log" 2>&1 || { cat "$detail_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$detail_log" || ! rg -Fq 'DETAIL_MODELS_RESULT: []' "$detail_log"; then
  cat "$detail_log"
  exit 1
fi
plant_log="$(mktemp -t zend-garden-plants)"
"$GODOT_BIN" --headless --path "$PWD" --script tests/plant_models.gd > "$plant_log" 2>&1 || { cat "$plant_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$plant_log" || ! rg -Fq 'PLANT_MODELS_RESULT: []' "$plant_log"; then
  cat "$plant_log"
  exit 1
fi
preview_log="$(mktemp -t zend-garden-preview)"
"$GODOT_BIN" --headless --path "$PWD" --script tests/plant_preview.gd > "$preview_log" 2>&1 || { cat "$preview_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$preview_log" || ! rg -Fq 'PLANT_PREVIEW_RESULT: []' "$preview_log"; then
  cat "$preview_log"
  exit 1
fi
wildlife_log="$(mktemp -t zend-garden-wildlife)"
"$GODOT_BIN" --headless --path "$PWD" --script tests/wildlife_direction.gd > "$wildlife_log" 2>&1 || { cat "$wildlife_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$wildlife_log" || ! rg -Fq 'WILDLIFE_DIRECTION_RESULT: []' "$wildlife_log"; then
  cat "$wildlife_log"
  exit 1
fi
test_exit=0
# macOS may stop drawing an obscured window; screenshot awaits need visible frames.
"$GODOT_BIN" --always-on-top --path "$PWD" -- --smoke-test > "$logfile" 2>&1 || test_exit=$?
cat "$logfile"
if rg -q 'SCRIPT ERROR|ERROR:|RESULT: \[[^]]' "$logfile"; then
  exit 1
fi
rg -q 'ZEND_GARDEN_TEST_RESULT: PASS' "$logfile"
exit $test_exit
