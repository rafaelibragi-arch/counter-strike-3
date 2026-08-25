# Clashpoint (Godot)

Year-1 CS-like tactical FPS — **desktop app + browser (HTML5)** from one Godot 4.7 project.

## Run

```bash
./godot/run.sh
```

Main menu → Training / Casual Bots / DM / Ranked / Host LAN.

## Exports

```bash
# Desktop
./godot/run.sh --headless --export-release "macOS" export/Clashpoint.app

# Web
./godot/scripts/export_web.sh
cd godot/export/web && python3 -m http.server 8081
```

## What's implemented

| System | Status |
|--------|--------|
| Source/CS2 pmove | Done (64 Hz, Jolt) |
| Weapons (18) + spray patterns | Done |
| Hitscan + armor + recoil | Done |
| Bots + navmesh | Done |
| Rounds MR12 + bomb | Done |
| Economy + buy | Done |
| Grenades (g=19.2) | Done |
| Maps dust2 / mirage / inferno / training | Done |
| Ladders | Done |
| LAN / matchmaking / dedicated stubs | Done |
| Dual client export | Done — see `docs/DUAL_CLIENT.md` |

## Verify

```bash
./godot/run.sh --headless -s res://scripts/verify_pmove.gd
./godot/run.sh --headless -s res://scripts/verify_year1.gd
./godot/run.sh --headless -s res://scripts/verify_match_boot.gd
./godot/run.sh --headless -s res://scripts/verify_ship.gd
```
