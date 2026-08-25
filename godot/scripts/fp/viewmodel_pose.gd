class_name ViewModelPose
extends Resource
## Per-weapon attachment pose for FP hands + weapon root.

@export var weapon_id: StringName = &"ak"
@export var weapon_pos: Vector3 = Vector3(0.2, -0.06, -0.18)
@export var weapon_rot: Vector3 = Vector3.ZERO
@export var right_hand_pos: Vector3 = Vector3(0.28, -0.10, -0.18)
@export var right_hand_rot: Vector3 = Vector3(0.15, -0.15, 1.15)
@export var left_hand_pos: Vector3 = Vector3(0.18, -0.08, -0.52)
@export var left_hand_rot: Vector3 = Vector3(0.35, 0.12, -0.55)
@export var show_left_hand: bool = true
@export var ads_hide_mesh: bool = false
@export var kick_mul: float = 1.0
@export var bob_scale: float = 1.0
