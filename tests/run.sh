#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
python3 tests/check_assets.py
python3 tests/check_greenhouse.py
python3 tests/check_mountains.py
python3 tests/check_plants.py
python3 tests/check_plant_growth.py
python3 tests/check_botanical_additions.py
python3 tests/check_low_grasses.py
python3 tests/check_audio.py
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
logfile="$(mktemp -t zend-garden-test)"
import_log="$(mktemp -t zend-garden-import)"
"$GODOT_BIN" --headless --path "$PWD" --editor --import > "$import_log" 2>&1 || { cat "$import_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$import_log"; then
  cat "$import_log"
  exit 1
fi
save_log="$(mktemp -t zend-garden-save-files)"
"$GODOT_BIN" --headless --path "$PWD" --script tests/save_files.gd > "$save_log" 2>&1 || { cat "$save_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$save_log" || ! rg -Fq 'SAVE_FILES_RESULT: []' "$save_log"; then
  cat "$save_log"
  exit 1
fi
audio_log="$(mktemp -t zend-garden-audio)"
"$GODOT_BIN" --headless --path "$PWD" --script tests/soundscape.gd > "$audio_log" 2>&1 || { cat "$audio_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$audio_log" || ! rg -Fq 'SOUNDSCAPE_RESULT: []' "$audio_log"; then
  cat "$audio_log"
  exit 1
fi
compression_log="$(mktemp -t zend-garden-compression)"
"$GODOT_BIN" --headless --path "$PWD" --script tests/audio_compression.gd > "$compression_log" 2>&1 || { cat "$compression_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$compression_log" || ! rg -Fq 'AUDIO_COMPRESSION_RESULT: []' "$compression_log"; then
  cat "$compression_log"
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
overhaul_log="$(mktemp -t zend-garden-overhaul)"
"$GODOT_BIN" --headless --path "$PWD" --script tests/overhaul_models.gd > "$overhaul_log" 2>&1 || { cat "$overhaul_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$overhaul_log" || ! rg -Fq 'OVERHAUL_MODELS_RESULT: []' "$overhaul_log"; then
  cat "$overhaul_log"
  exit 1
fi
plant_log="$(mktemp -t zend-garden-plants)"
supplied_log="$(mktemp -t zend-garden-supplied)"
"$GODOT_BIN" --headless --path "$PWD" --script tests/supplied_animals.gd > "$supplied_log" 2>&1 || { cat "$supplied_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$supplied_log" || ! rg -Fq 'SUPPLIED_ANIMALS_RESULT: []' "$supplied_log"; then
  cat "$supplied_log"
  exit 1
fi
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
improvements_log="$(mktemp -t zend-garden-improvements)"
"$GODOT_BIN" --headless --path "$PWD" --script tests/plant_improvements.gd > "$improvements_log" 2>&1 || { cat "$improvements_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$improvements_log" || ! rg -Fq 'PLANT_IMPROVEMENTS_RESULT: []' "$improvements_log"; then
  cat "$improvements_log"
  exit 1
fi
"$GODOT_BIN" --headless --path "$PWD" --script tests/wildlife_direction.gd > "$wildlife_log" 2>&1 || { cat "$wildlife_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$wildlife_log" || ! rg -Fq 'WILDLIFE_DIRECTION_RESULT: []' "$wildlife_log"; then
  cat "$wildlife_log"
  exit 1
fi
in_game_log="$(mktemp -t zend-garden-improvements-game)"
"$GODOT_BIN" --always-on-top --path "$PWD" -- --improvements-test > "$in_game_log" 2>&1 || { cat "$in_game_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$in_game_log" || ! rg -Fq 'IMPROVEMENTS_IN_GAME_RESULT: []' "$in_game_log"; then
  cat "$in_game_log"
  exit 1
fi
compat_log="$(mktemp -t zend-garden-improvements-compat)"
"$GODOT_BIN" --rendering-method gl_compatibility --always-on-top --path "$PWD" --script tests/plant_improvements.gd > "$compat_log" 2>&1 || { cat "$compat_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$compat_log" || ! rg -Fq 'PLANT_IMPROVEMENTS_RESULT: []' "$compat_log"; then
  cat "$compat_log"
  exit 1
fi
"$GODOT_BIN" --rendering-method gl_compatibility --always-on-top --path "$PWD" -- --improvements-test > "$compat_log" 2>&1 || { cat "$compat_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$compat_log" || ! rg -Fq 'IMPROVEMENTS_IN_GAME_RESULT: []' "$compat_log"; then
  cat "$compat_log"
  exit 1
fi
for renderer in forward_plus gl_compatibility; do
  dense_log="$(mktemp -t zend-garden-dense)"
  "$GODOT_BIN" --rendering-method "$renderer" --always-on-top --path "$PWD" --script tests/dense_garden.gd > "$dense_log" 2>&1 || { cat "$dense_log"; exit 1; }
  if rg -q 'SCRIPT ERROR|ERROR:' "$dense_log" || ! rg -Fq 'DENSE_GARDEN_RESULT: []' "$dense_log"; then
    cat "$dense_log"
    exit 1
  fi
  view_log="$(mktemp -t zend-garden-view-water)"
  "$GODOT_BIN" --rendering-method "$renderer" --always-on-top --path "$PWD" -- --view-water-test > "$view_log" 2>&1 || { cat "$view_log"; exit 1; }
  if rg -q 'SCRIPT ERROR|ERROR:' "$view_log" || ! rg -Fq 'VIEW_WATER_RESULT: []' "$view_log"; then
    cat "$view_log"
    exit 1
  fi
done
for feature in tutorial inhabit; do
  feature_log="$(mktemp -t zend-garden-$feature)"
  "$GODOT_BIN" --always-on-top --path "$PWD" -- --"$feature"-test > "$feature_log" 2>&1 || { cat "$feature_log"; exit 1; }
  if rg -q 'SCRIPT ERROR|ERROR:|RESULT: \[[^]]' "$feature_log"; then
    cat "$feature_log"
    exit 1
  fi
  rg -q 'TUTORIAL_RESULT: \[\]|LEISURE_RESULT: \[\]' "$feature_log"
done
test_exit=0
# macOS may stop drawing an obscured window; screenshot awaits need visible frames.
"$GODOT_BIN" --always-on-top --path "$PWD" -- --smoke-test > "$logfile" 2>&1 || test_exit=$?
cat "$logfile"
if rg -q 'SCRIPT ERROR|ERROR:|RESULT: \[[^]]' "$logfile"; then
  exit 1
fi
rg -q 'ZEND_GARDEN_TEST_RESULT: PASS' "$logfile"
exit $test_exit
