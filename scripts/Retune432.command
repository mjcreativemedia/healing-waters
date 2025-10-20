#!/usr/bin/env bash
set -euo pipefail
choose_dir() {
  osascript <<'APPLESCRIPT'
  tell application "System Events" to activate
  tell application (path to frontmost application as text)
    set theFolder to choose folder with prompt "Select a folder"
    POSIX path of theFolder
  end tell
APPLESCRIPT
}
INPUT_DIR=$(choose_dir || true)
if [[ -z "${INPUT_DIR:-}" ]]; then
  echo "No input folder selected."
  exit 1
fi
OUTPUT_DIR=$(choose_dir || true)
if [[ -z "${OUTPUT_DIR:-}" ]]; then
  echo "No output folder selected."
  exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENGINE="$ROOT_DIR/core/retune_432.py"
/usr/bin/env python3 "$ENGINE" "$INPUT_DIR" "$OUTPUT_DIR"
osascript -e 'display notification "Retune to 432 Hz complete." with title "Healing Waters"'
