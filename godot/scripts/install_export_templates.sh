#!/usr/bin/env bash
set -euo pipefail
VER="${1:-4.7.2.stable}"
SHORT="${VER%.stable}"
DEST="$HOME/Library/Application Support/Godot/export_templates/$VER"
TMP="/tmp/godot_templates_${SHORT}.tpz"
URL="https://downloads.tuxfamily.org/godotengine/${SHORT}/Godot_v${SHORT}-stable_export_templates.tpz"
mkdir -p "$(dirname "$DEST")"
echo "Downloading $URL → $TMP"
curl -L --fail --retry 3 -o "$TMP" "$URL"
echo "Extracting…"
rm -rf "$DEST"
mkdir -p "$DEST"
# tpz is a zip
unzip -q -o "$TMP" -d "/tmp/godot_templates_extract_${SHORT}"
# Contents usually under templates/
if [[ -d "/tmp/godot_templates_extract_${SHORT}/templates" ]]; then
  mv "/tmp/godot_templates_extract_${SHORT}/templates"/* "$DEST/" 2>/dev/null || true
  # Sometimes extract creates version folder already named
  if [[ -z "$(ls -A "$DEST")" ]]; then
    mv "/tmp/godot_templates_extract_${SHORT}/templates" "$DEST"
  fi
else
  # flat
  cp -R /tmp/godot_templates_extract_${SHORT}/* "$DEST/"
fi
ls "$DEST" | head
echo "Installed templates → $DEST"
