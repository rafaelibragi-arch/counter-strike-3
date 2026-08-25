class_name ViewModelConfig
extends Resource
## FP viewmodel tuning — Godot source of truth (mirrored to browser JSON).

@export_group("Base Offset")
@export var offset_x: float = 0.18
@export var offset_y: float = -0.12
@export var offset_z: float = -0.18
@export var scale: float = 1.0

@export_group("Bob")
@export var bob_amount: float = 1.0
@export var bob_y_amp: float = 0.012
@export var bob_x_amp: float = 0.008
@export var run_bob_speed: float = 11.5
@export var walk_bob_speed: float = 8.2
@export var crouch_bob_speed: float = 6.2
@export var crouch_bob_scale: float = 0.42
@export var walk_bob_scale: float = 0.62

@export_group("Kick")
@export var kick_decay: float = 8.0
@export var kick_rot_decay: float = 7.0
@export var kick_pos_mul: float = 0.15

@export_group("ADS")
@export var ads_rifle_fov: float = 70.0
@export var ads_sniper_fov: float = 45.0
@export var ads_lerp_speed: float = 12.0
@export var precision_offset := Vector3(0.08, -0.1, -0.28)
@export var sniper_ads_offset := Vector3(0.02, -0.42, 0.15)

@export_group("Switch")
@export var draw_time: float = 0.35
@export var holster_z: float = 0.4
@export var holster_rot: float = 0.8

@export_group("Layers")
@export var viewmodel_layer: int = 2
@export var world_layer: int = 1

@export_group("VFX")
@export var muzzle_flash_frames: float = 0.06
@export var shell_eject_quality_min: int = 1 ## 0=off 1=med 2=ultra
