# FP Viewmodel Assets

Shared first-person assets for Godot (source of truth) and browser mirror.

## Files

| Path | Description |
|------|-------------|
| `viewmodel_constants.json` | Exported from Godot — bob/ADS/poses |
| `weapon_{id}.glb` | Optional per-weapon mesh (browser loads if present) |
| `arms_ct.glb` / `arms_t.glb` | Optional skinned arms (future) |

## Export constants

```bash
./godot/run.sh --headless -s res://scripts/export/viewmodel_constants.gd
```

## GLB weapons

Until real GLB files are added, Godot uses procedural meshes via `viewmodel_mesh_factory.gd`.
Browser falls back to procedural `buildWeaponModel()` in `index.html`.

Tier-1 ids: `ak`, `m4`, `awp`, `usps`, `glock`, `deagle`, `knife`
