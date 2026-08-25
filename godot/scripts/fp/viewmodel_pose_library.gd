class_name ViewModelPoseLibrary
extends RefCounted
## Weapon pose registry — ports handPoseForWeapon() from browser index.html.

const ViewModelPoseRes := preload("res://scripts/fp/viewmodel_pose.gd")

static var _poses: Dictionary = {}


static func get_pose(weapon_id: StringName) -> Resource:
	if _poses.is_empty():
		_build()
	return _poses.get(weapon_id, _poses[&"ak"])


static func all() -> Dictionary:
	if _poses.is_empty():
		_build()
	return _poses


static func _make(
	wid: StringName,
	wpos: Vector3,
	wrot: Vector3,
	rpos: Vector3,
	rrot: Vector3,
	lpos: Vector3,
	lrot: Vector3,
	left: bool = true,
	ads_hide: bool = false,
	kick: float = 1.0,
	bob: float = 1.0,
) -> Resource:
	var p = ViewModelPoseRes.new()
	p.weapon_id = wid
	p.weapon_pos = wpos
	p.weapon_rot = wrot
	p.right_hand_pos = rpos
	p.right_hand_rot = rrot
	p.left_hand_pos = lpos
	p.left_hand_rot = lrot
	p.show_left_hand = left
	p.ads_hide_mesh = ads_hide
	p.kick_mul = kick
	p.bob_scale = bob
	return p


static func _build() -> void:
	var rifle_r := Vector3(0.28, -0.10, -0.18)
	var rifle_rr := Vector3(0.15, -0.15, 1.15)
	var rifle_l := Vector3(0.18, -0.08, -0.52)
	var rifle_lr := Vector3(0.35, 0.12, -0.55)
	var wp := Vector3(0.2, -0.06, -0.18)

	_poses[&"ak"] = _make(&"ak", wp, Vector3.ZERO, rifle_r, rifle_rr, rifle_l, rifle_lr)
	_poses[&"galil"] = _poses[&"ak"]
	_poses[&"m4"] = _poses[&"ak"]
	_poses[&"m4a1s"] = _poses[&"ak"]

	_poses[&"awp"] = _make(
		&"awp", wp, Vector3.ZERO,
		Vector3(0.26, -0.2, -0.28), Vector3(0.25, -0.1, 0.4),
		Vector3(0.22, -0.16, -0.78), Vector3(0.45, 0.05, -0.25),
		true, true, 1.2, 0.85,
	)

	_poses[&"knife"] = _make(
		&"knife", wp, Vector3.ZERO,
		Vector3(0.22, -0.14, -0.18), Vector3(0.15, -0.55, 0.85),
		Vector3(0.08, -0.16, -0.32), Vector3(0.4, 0.35, -0.9),
	)

	var pistol_r := Vector3(0.24, -0.18, -0.26)
	var pistol_rr := Vector3(0.35, -0.05, 0.25)
	var pistol_l := Vector3(0.14, -0.14, -0.38)
	var pistol_lr := Vector3(0.55, 0.2, -0.55)
	for wid: StringName in [&"glock", &"usps", &"p250", &"pistol", &"deagle"]:
		_poses[wid] = _make(wid, wp, Vector3.ZERO, pistol_r, pistol_rr, pistol_l, pistol_lr, true, false, 0.9, 0.75)

	var smg_r := Vector3(0.25, -0.2, -0.3)
	var smg_rr := Vector3(0.3, -0.08, 0.4)
	var smg_l := Vector3(0.2, -0.16, -0.62)
	var smg_lr := Vector3(0.5, 0.08, -0.35)
	for wid: StringName in [&"mac10", &"mp9", &"ump", &"mp7"]:
		_poses[wid] = _make(wid, wp, Vector3.ZERO, smg_r, smg_rr, smg_l, smg_lr)

	var sg_r := Vector3(0.26, -0.2, -0.3)
	var sg_rr := Vector3(0.28, -0.08, 0.38)
	var sg_l := Vector3(0.22, -0.14, -0.82)
	var sg_lr := Vector3(0.35, 0.0, -0.2)
	for wid: StringName in [&"nova", &"xm", &"mag7"]:
		_poses[wid] = _make(wid, wp, Vector3.ZERO, sg_r, sg_rr, sg_l, sg_lr, true, false, 1.1, 0.9)
