extends SceneTree
## Export viewmodel constants JSON for browser mirror.

const OUT_PATH := "res://../assets/fp/viewmodel_constants.json"
const ViewModelPoseLibrary := preload("res://scripts/fp/viewmodel_pose_library.gd")
const ViewModelConfigRes := preload("res://resources/viewmodel_config.tres")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var cfg = ViewModelConfigRes
	if cfg == null:
		cfg = load("res://resources/viewmodel_config.tres")

	var poses: Dictionary = {}
	for wid: StringName in ViewModelPoseLibrary.all().keys():
		var p = ViewModelPoseLibrary.get_pose(wid)
		poses[String(wid)] = {
			"weapon_pos": [p.weapon_pos.x, p.weapon_pos.y, p.weapon_pos.z],
			"weapon_rot": [p.weapon_rot.x, p.weapon_rot.y, p.weapon_rot.z],
			"right_hand_pos": [p.right_hand_pos.x, p.right_hand_pos.y, p.right_hand_pos.z],
			"right_hand_rot": [p.right_hand_rot.x, p.right_hand_rot.y, p.right_hand_rot.z],
			"left_hand_pos": [p.left_hand_pos.x, p.left_hand_pos.y, p.left_hand_pos.z],
			"left_hand_rot": [p.left_hand_rot.x, p.left_hand_rot.y, p.left_hand_rot.z],
			"show_left_hand": p.show_left_hand,
			"ads_hide_mesh": p.ads_hide_mesh,
			"kick_mul": p.kick_mul,
			"bob_scale": p.bob_scale,
		}

	var data := {
		"version": 1,
		"source": "godot",
		"offset": [cfg.offset_x, cfg.offset_y, cfg.offset_z],
		"scale": cfg.scale,
		"bob": {
			"amount": cfg.bob_amount,
			"y_amp": cfg.bob_y_amp,
			"x_amp": cfg.bob_x_amp,
			"run_speed": cfg.run_bob_speed,
			"walk_speed": cfg.walk_bob_speed,
			"crouch_speed": cfg.crouch_bob_speed,
			"crouch_scale": cfg.crouch_bob_scale,
			"walk_scale": cfg.walk_bob_scale,
		},
		"kick": {"decay": cfg.kick_decay, "rot_decay": cfg.kick_rot_decay, "pos_mul": cfg.kick_pos_mul},
		"ads": {
			"rifle_fov": cfg.ads_rifle_fov,
			"sniper_fov": cfg.ads_sniper_fov,
			"lerp_speed": cfg.ads_lerp_speed,
			"precision_offset": [cfg.precision_offset.x, cfg.precision_offset.y, cfg.precision_offset.z],
			"sniper_offset": [cfg.sniper_ads_offset.x, cfg.sniper_ads_offset.y, cfg.sniper_ads_offset.z],
		},
		"switch": {"draw_time": cfg.draw_time, "holster_z": cfg.holster_z, "holster_rot": cfg.holster_rot},
		"poses": poses,
		"glb_paths": {
			"arms_ct": "assets/fp/arms_ct.glb",
			"arms_t": "assets/fp/arms_t.glb",
			"weapon_pattern": "assets/fp/weapon_{id}.glb",
		},
	}

	var json := JSON.stringify(data, "\t")
	var abs := ProjectSettings.globalize_path(OUT_PATH)
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f == null:
		printerr("FAIL: cannot write ", abs)
		quit(1)
		return
	f.store_string(json)
	f.close()
	print("EXPORT_VIEWMODEL_CONSTANTS_OK ", abs)
	quit(0)
