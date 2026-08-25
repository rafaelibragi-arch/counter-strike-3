# FP Viewmodel — Clashpoint (Godot source of truth)

## Architecture

```
Player/Head/Camera3D/ViewModel  →  ViewModelController
  ├── WeaponView (ViewModelWeapon)
  ├── Vfx (ViewModelVfx)
  └── AnimPlayer
HUD/ScopeOverlay                →  AWP ADS vignette
```

Shared assets (future GLB): `assets/fp/weapon_{id}.glb`, `assets/fp/arms_ct.glb`, `assets/fp/arms_t.glb`

Browser mirror reads `assets/fp/viewmodel_constants.json` (export via `scripts/export/viewmodel_constants.gd`).

## Render layers

| Layer | Bit | Usage |
|-------|-----|--------|
| world | 1 | Map geometry |
| viewmodel | 2 | FP arms + weapon + vm lights |

Main camera `cull_mask = 3` (world + viewmodel). Vm lights use layer 2 only.

## Bone / node naming (GLB import checklist)

| Node | Purpose |
|------|---------|
| `weapon_socket` | Attachment for weapon root |
| `mag` | Detachable magazine (reload anim) |
| `muzzle` | Muzzle flash / shell eject origin |
| `scope_glass` | AWP optic (optional) |
| `RightHand` / `LeftHand` | Glove meshes |

## Import settings (Godot 4.7)

- Meshes: generate LODs **off**
- Materials: extract **embedded**
- Collision: **none**
- Animation: import if skeletal clips present

## Scripts

| File | Role |
|------|------|
| `scripts/fp/viewmodel_controller.gd` | Bob, kick, ADS, reload, switch |
| `scripts/fp/viewmodel_weapon.gd` | Mesh swap, skins |
| `scripts/fp/viewmodel_mesh_factory.gd` | Procedural placeholder meshes |
| `scripts/fp/viewmodel_pose_library.gd` | Per-weapon poses |
| `scripts/fp/viewmodel_skin.gd` | Glove / paint colors |
| `resources/viewmodel_config.tres` | Tunable constants |

## Verification

```bash
./godot/run.sh --headless -s res://scripts/verify_viewmodel.gd
./godot/run.sh --headless -s res://scripts/export/viewmodel_constants.gd
```

Browser QA: `window.__CS3.dumpViewmodel()` after match start.

## Settings (GameState)

- `viewmodel_scale` (0.7–1.3)
- `weapon_bob` (0–1.5)
- `recoil_cam`
- `quality` → VFX tier (perf/med/ultra)

## Input

- **Right mouse** → `aim` (ADS)
- Rifle ADS: FOV ~70, lowered sights pose
- AWP ADS: FOV ~45, scope overlay, hide weapon mesh
