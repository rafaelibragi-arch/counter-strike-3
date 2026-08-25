#!/usr/bin/env bash
# Export Clashpoint web build (requires Godot export templates for 4.7.x).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${ROOT}/../tools/Godot.app/Contents/MacOS/Godot"
OUT="${ROOT}/export/web"
mkdir -p "$OUT"
if [[ ! -x "$GODOT" ]]; then
  echo "Godot missing at $GODOT"
  exit 1
fi
TEMPLATES="$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable"
if [[ ! -d "$TEMPLATES" ]]; then
  echo "Export templates not installed at: $TEMPLATES"
  echo "Install via Godot → Editor → Manage Export Templates, or:"
  echo "  ./godot/scripts/install_export_templates.sh"
  exit 2
fi
"$GODOT" --path "$ROOT" --headless --export-release "Web" "$OUT/index.html"
echo "Web export OK → $OUT/index.html"
