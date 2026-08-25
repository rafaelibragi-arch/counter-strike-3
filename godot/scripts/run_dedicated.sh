#!/usr/bin/env bash
# Headless dedicated-server stub (Year-1 LAN / future online).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${ROOT}/../tools/Godot.app/Contents/MacOS/Godot"
exec "$GODOT" --path "$ROOT" --headless --script res://scripts/net/dedicated_stub.gd "$@"
