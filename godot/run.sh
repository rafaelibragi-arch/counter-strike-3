#!/usr/bin/env bash
# Launch Clashpoint Godot movement prototype.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${ROOT}/tools/Godot.app/Contents/MacOS/Godot"
if [[ ! -x "$GODOT" ]]; then
  echo "Godot not found at $GODOT"
  echo "Download 4.7+ macOS build into tools/ first."
  exit 1
fi
exec "$GODOT" --path "${ROOT}/godot" "$@"
