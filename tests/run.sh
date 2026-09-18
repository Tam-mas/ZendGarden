#!/bin/zsh
set -eu
cd "$(dirname "$0")/.."
python3 tests/check_assets.py
python3 tests/check_audio.py
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}"
logfile="$(mktemp -t zend-garden-test)"
import_log="$(mktemp -t zend-garden-import)"
"$GODOT_BIN" --headless --path "$PWD" --editor --import > "$import_log" 2>&1 || { cat "$import_log"; exit 1; }
if rg -q 'SCRIPT ERROR|ERROR:' "$import_log"; then
  cat "$import_log"
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
if rg -q 'SCRIPT ERROR|ERROR:|RESULT: \[' "$logfile"; then
  exit 1
fi
rg -q 'ZEND_GARDEN_TEST_RESULT: PASS' "$logfile"
exit $test_exit
