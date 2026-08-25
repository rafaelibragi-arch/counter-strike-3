class_name ViewModelController
extends Node3D
## FP viewmodel: bob, kick, ADS, reload, draw/holster, combat sync.

const ViewModelWeaponScript := preload("res://scripts/fp/viewmodel_weapon.gd")
const ViewModelVfxScript := preload("res://scripts/fp/viewmodel_vfx.gd")
const ViewModelPoseLib := preload("res://scripts/fp/viewmodel_pose_library.gd")
const ViewModelConfigScript := preload("res://scripts/fp/viewmodel_config.gd")

@export var config: Resource
@export var weapon_controller_path: NodePath
@export var player_path: NodePath
@export var camera_path: NodePath

var ads: bool = false
var precision_aim: bool = false
var visible_vm: bool = true

var _weapon: Node3D
var _vfx: Node3D
var _anim: AnimationPlayer
var _camera: Camera3D
var _player: CharacterBody3D
var _wc: WeaponController
var _config: Resource

var _bob_phase: float = 0.0
var _kick: float = 0.0
var _kick_rot: float = 0.0
var _reload_t: float = 0.0
var _reload_active: bool = false
var _reload_duration: float = 2.5
var _switch_t: float = 1.0
var _switching: bool = false
var _pending_weapon: StringName = &""
var _was_on_floor: bool = true
var _land_dip: float = 0.0
var _jump_squash: float = 0.0
var _lag_pitch: float = 0.0
var _lag_yaw: float = 0.0
var _base_fov: float = 90.0
var _ads_blend: float = 0.0
var _knife_swing: float = 0.0
var _knife_mode: int = 0
var _left_hand: bool = false


func _ready() -> void:
	_config = config
	if _config == null:
		_config = load("res://resources/viewmodel_config.tres")
	if _config == null:
		_config = ViewModelConfigScript.new()

	_camera = get_node_or_null(camera_path) as Camera3D
	if _camera == null:
		_camera = get_parent() as Camera3D
	_player = get_node_or_null(player_path) as CharacterBody3D
	if _player == null:
		var n: Node = self
		while n and _player == null:
			if n is CharacterBody3D:
				_player = n as CharacterBody3D
			n = n.get_parent()
	_wc = get_node_or_null(weapon_controller_path) as WeaponController
	if _wc == null and _player:
		_wc = _player.get_node_or_null("WeaponController") as WeaponController

	_base_fov = _gs_setting("fov", 90.0)
	if _camera:
		_camera.fov = _base_fov
		_camera.cull_mask = _config.world_layer | _config.viewmodel_layer

	_setup_lights()
	_weapon = ViewModelWeaponScript.new()
	_weapon.name = "WeaponView"
	add_child(_weapon)

	_vfx = ViewModelVfxScript.new()
	_vfx.name = "Vfx"
	if _vfx.has_method("set_quality"):
		_vfx.set_quality(_quality_tier())
	add_child(_vfx)

	_anim = AnimationPlayer.new()
	_anim.name = "AnimPlayer"
	add_child(_anim)
	_build_reload_animation()

	var team := WeaponDefinition.Team.CT
	if _player:
		var c := _player.get_node_or_null("Combatant") as Combatant
		if c:
			team = c.team
	_weapon.setup(team, _skin_dict())
	_connect_weapon_controller()
	call_deferred("_sync_weapon_from_combatant")
	call_deferred("_late_init")


func _setup_lights() -> void:
	var key := SpotLight3D.new()
	key.name = "VmKey"
	key.light_color = Color(1.0, 0.95, 0.88)
	key.light_energy = 2.4
	key.spot_range = 4.5
	key.spot_angle = 55.0
	key.shadow_enabled = false
	key.layers = _config.viewmodel_layer
	key.position = Vector3(0.35, 0.55, 0.2)
	key.rotation = Vector3(-0.9, 0.35, 0)
	add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "VmFill"
	fill.light_color = Color(0.66, 0.77, 0.91)
	fill.light_energy = 0.85
	fill.omni_range = 3.2
	fill.shadow_enabled = false
	fill.layers = _config.viewmodel_layer
	fill.position = Vector3(-0.25, 0.15, 0.1)
	add_child(fill)

	var rim := OmniLight3D.new()
	rim.name = "VmRim"
	rim.light_color = Color(1.0, 0.8, 0.53)
	rim.light_energy = 0.55
	rim.omni_range = 2.8
	rim.shadow_enabled = false
	rim.layers = _config.viewmodel_layer
	rim.position = Vector3(0.15, -0.2, -0.9)
	add_child(rim)


func _late_init() -> void:
	if _player == null:
		_player = get_node_or_null(player_path) as CharacterBody3D
	if _camera == null:
		_camera = get_node_or_null(camera_path) as Camera3D
	if _wc == null:
		_wc = get_node_or_null(weapon_controller_path) as WeaponController
	_connect_weapon_controller()
	_sync_weapon_from_combatant()


func _connect_weapon_controller() -> void:
	if _wc == null:
		return
	if not _wc.shot_fired.is_connected(_on_shot_fired):
		_wc.shot_fired.connect(_on_shot_fired)
	if not _wc.reloaded.is_connected(_on_reloaded):
		_wc.reloaded.connect(_on_reloaded)
	if not _wc.weapon_switched.is_connected(_on_weapon_switched):
		_wc.weapon_switched.connect(_on_weapon_switched)
	if not _wc.reload_started.is_connected(_on_reload_started):
		_wc.reload_started.connect(_on_reload_started)


func _process(delta: float) -> void:
	if _weapon == null:
		return
	if _wc and not _switching and not _reload_active:
		var cw = _wc.current_weapon()
		if cw and _weapon.weapon_id != cw.id:
			_begin_switch(cw.id)

	_kick = maxf(0.0, _kick - delta * _config.kick_decay)
	_kick_rot = maxf(0.0, _kick_rot - delta * _config.kick_rot_decay)
	_land_dip = maxf(0.0, _land_dip - delta * 8.0)
	_jump_squash = maxf(0.0, _jump_squash - delta * 6.0)
	_knife_swing = maxf(0.0, _knife_swing - delta * 2.5)
	_lag_pitch = lerpf(_lag_pitch, 0.0, minf(1.0, delta * 10.0))
	_lag_yaw = lerpf(_lag_yaw, 0.0, minf(1.0, delta * 10.0))

	if _reload_active and _reload_duration > 0.0:
		_reload_t = minf(1.0, _reload_t + delta / _reload_duration)
		_apply_reload_mag(_reload_t)
		if _reload_t >= 1.0:
			_reload_active = false
			_weapon.reset_mag_transform()

	_update_switch(delta)
	_update_motion(delta)
	_update_ads(delta)
	_apply_transform()

	if _player and not _player_is_alive():
		visible_vm = false
	visible = visible_vm


func _physics_process(_delta: float) -> void:
	if _player == null:
		return
	var on_floor := _player.is_on_floor()
	if not _was_on_floor and on_floor:
		var vy: float = float(_player.get_meta("last_vy", 0.0))
		if vy < -4.5:
			_land_dip = 1.0
		elif vy < -2.5:
			_land_dip = 0.45
	if _was_on_floor and not on_floor:
		_jump_squash = 0.6
	_was_on_floor = on_floor
	_player.set_meta("crouching", _player_is_crouching())


func set_ads(on: bool) -> void:
	ads = on
	if on:
		precision_aim = false


func set_precision_aim(on: bool) -> void:
	if ads:
		return
	precision_aim = on


func set_visible_vm(on: bool) -> void:
	visible_vm = on


func dump_state() -> Dictionary:
	var w := _wc.current_weapon() if _wc else null
	return {
		"weapon": String(w.id) if w else "",
		"ads": ads,
		"bob": _bob_phase,
		"kick": _kick,
		"reload": _reload_t,
		"is_glb": false,
		"visible": visible_vm,
		"scale": _config.scale,
	}


func _update_motion(delta: float) -> void:
	if _player == null:
		return
	var move_sp := Vector2(_player.velocity.x, _player.velocity.z).length()
	var frozen := false
	var walking := Input.is_action_pressed("walk")
	var crouching := _player_is_crouching()
	var on_ground := _player.is_on_floor()
	var moving := move_sp > 0.55 and on_ground and not frozen

	var bob_amt: float = float(_gs_setting("weapon_bob", 1.0))
	bob_amt *= _config.bob_amount
	var pose = ViewModelPoseLib.get_pose(_weapon.weapon_id)
	bob_amt *= pose.bob_scale

	var bob_spd: float = float(_config.get("run_bob_speed"))
	var bob_scale: float = 1.0
	if crouching:
		bob_spd = float(_config.get("crouch_bob_speed"))
		bob_scale = float(_config.get("crouch_bob_scale"))
	elif walking:
		bob_spd = float(_config.get("walk_bob_speed"))
		bob_scale = float(_config.get("walk_bob_scale"))

	var air_mul := 1.0 if on_ground else 0.22
	if moving:
		var run_ref := 6.0
		if _player.has_method("get") and _player.get("config"):
			var mc := _player.get("config") as MoveConfig
			if mc:
				run_ref = mc.run_speed
		_bob_phase += delta * bob_spd * (0.85 + minf(1.0, move_sp / run_ref) * 0.35)


func _apply_transform() -> void:
	var move_sp := 0.0
	var crouching := false
	var on_ground := true
	if _player:
		move_sp = Vector2(_player.velocity.x, _player.velocity.z).length()
		crouching = _player_is_crouching()
		on_ground = _player.is_on_floor()

	var frozen := false
	var walking := Input.is_action_pressed("walk")
	var moving := move_sp > 0.55 and on_ground and not frozen
	var bob_amt: float = float(_gs_setting("weapon_bob", 1.0))
	bob_amt *= float(_config.get("bob_amount"))
	var bob_scale: float = 1.0
	if crouching:
		bob_scale = float(_config.get("crouch_bob_scale"))
	elif walking:
		bob_scale = float(_config.get("walk_bob_scale"))
	var air_mul: float = 1.0 if on_ground else 0.22

	var bob_y: float = 0.0
	var bob_x: float = 0.0
	if moving:
		bob_y = sin(_bob_phase) * float(_config.get("bob_y_amp")) * bob_amt * bob_scale * air_mul
		bob_x = cos(_bob_phase * 0.5) * float(_config.get("bob_x_amp")) * bob_amt * bob_scale * air_mul

	var px: float = float(_config.get("offset_x")) + bob_x
	var py: float = float(_config.get("offset_y")) + bob_y + _kick * float(_config.get("kick_pos_mul"))
	var pz: float = float(_config.get("offset_z")) + _kick
	var rx := -_kick_rot - _lag_pitch * 0.35
	var ry := -_lag_yaw * 0.55
	var rz := _lag_yaw * 0.25

	py -= _land_dip * 0.07 + _jump_squash * 0.045
	if _player and _player.has_method("get") and _player.get("config"):
		var mc := _player.get("config") as MoveConfig
		if mc:
			var eye_h := mc.eye_standing
			if _player.has_method("get_eye_height"):
				eye_h = _player.get_eye_height()
			var duck_t := clampf((mc.eye_standing - eye_h) / (mc.eye_standing - mc.eye_crouch + 0.001), 0.0, 1.0)
			py -= duck_t * 0.045
			rz += duck_t * 0.05

	if precision_aim and not ads:
		px = _config.precision_offset.x
		py = _config.precision_offset.y
		pz = _config.precision_offset.z
		rx -= 0.05
		ry += 0.02

	if ads:
		var pose = ViewModelPoseLib.get_pose(_weapon.weapon_id)
		if pose.ads_hide_mesh:
			px = _config.sniper_ads_offset.x
			py = _config.sniper_ads_offset.y
			pz = _config.sniper_ads_offset.z
			_weapon.set_weapon_visible(false)
		else:
			_weapon.set_weapon_visible(true)
			px = _config.precision_offset.x
			py = _config.precision_offset.y
			pz = _config.precision_offset.z
	else:
		_weapon.set_weapon_visible(true)

	if _knife_swing > 0.0:
		var t := 1.0 - _knife_swing
		var wave := sin(minf(1.0, t * 1.15) * PI)
		if _knife_mode == 1:
			pz -= wave * 0.22
			py += wave * 0.04
			rx -= wave * 0.35
		else:
			ry += (1.0 if t < 0.5 else -1.0) * wave * 0.85
			rz += wave * 0.55
			px += wave * 0.1
			rx += wave * 0.2

	if _switching:
		var st := 1.0 - _switch_t
		pz += st * _config.holster_z
		rx += st * _config.holster_rot

	var vm_scale: float = float(_gs_setting("viewmodel_scale", 1.0))
	vm_scale *= _config.scale
	if _left_hand:
		px = -px
		ry = -ry

	scale = Vector3.ONE * vm_scale
	position = Vector3(px, py, pz)
	rotation = Vector3(rx, ry, rz)


func _update_ads(delta: float) -> void:
	if _camera == null:
		return
	var target := 0.0
	if ads:
		target = 1.0
	_ads_blend = lerpf(_ads_blend, target, minf(1.0, delta * _config.ads_lerp_speed))

	var w := _wc.current_weapon() if _wc else null
	var sniper := w != null and w.type == WeaponDefinition.Type.SNIPER
	var goal_fov := _base_fov
	if _ads_blend > 0.01:
		goal_fov = _config.ads_sniper_fov if sniper else _config.ads_rifle_fov
		goal_fov = lerpf(_base_fov, goal_fov, _ads_blend)
	_camera.fov = goal_fov
	_update_scope_overlay(sniper)


func _update_scope_overlay(sniper: bool) -> void:
	if _player == null:
		return
	var hud := _player.get_node_or_null("HUD")
	if hud == null:
		return
	var scope := hud.get_node_or_null("ScopeOverlay") as Control
	if scope:
		scope.visible = ads and sniper and _ads_blend > 0.5


func _update_switch(delta: float) -> void:
	if not _switching:
		return
	_switch_t = minf(1.0, _switch_t + delta / _config.draw_time)
	if _switch_t >= 0.5 and _pending_weapon != &"":
		_weapon.set_weapon(_pending_weapon)
		_pending_weapon = &""
	if _switch_t >= 1.0:
		_switching = false


func _apply_reload_mag(t: float) -> void:
	var mag: Node3D = _weapon.get_mag() as Node3D
	if mag == null:
		return
	var base: Transform3D = _weapon.get_mag_base()
	var tilt := clampf(t / 0.2, 0.0, 1.0) if t < 0.2 else 1.0
	var seat := clampf((t - 0.85) / 0.15, 0.0, 1.0) if t > 0.85 else 0.0
	var wave := sin(clampf((t - 0.15) / 0.7, 0.0, 1.0) * PI)
	var mag_out := 0.0
	if t < 0.2:
		mag_out = 0.0
	elif t < 0.45:
		mag_out = (t - 0.2) / 0.25
	elif t < 0.7:
		mag_out = 1.0
	else:
		mag_out = maxf(0.0, 1.0 - (t - 0.7) / 0.25)
	mag.transform = base
	mag.position += Vector3(mag_out * 0.08, -mag_out * 0.55, 0)
	mag.rotation += Vector3(mag_out * 1.2, 0, mag_out * 0.4)
	rotation.x += 0.25 * tilt + wave * 0.95 - seat * 0.15
	position.y -= 0.06 + wave * 0.2
	position.z += 0.04 + wave * 0.16


func _on_shot_fired(w: WeaponDefinition) -> void:
	var pose = ViewModelPoseLib.get_pose(w.id)
	_kick = 0.16 + w.recoil * 0.07
	_kick_rot = (0.2 + w.recoil * 0.08) * pose.kick_mul
	_lag_pitch += w.recoil * 0.012
	if w.type == WeaponDefinition.Type.MELEE:
		_knife_swing = 1.0
		_knife_mode = 0
	var heavy := w.type == WeaponDefinition.Type.SNIPER or w.type == WeaponDefinition.Type.SHOTGUN or String(w.id) == "deagle"
	_vfx.trigger_muzzle(_weapon.get_muzzle_global(), heavy)
	if w.type != WeaponDefinition.Type.MELEE and _quality_tier() >= 2:
		_vfx.trigger_shell(_weapon.get_muzzle_global() + Vector3(0.05, 0.02, 0))


func _on_reload_started(w: WeaponDefinition, duration: float) -> void:
	_reload_active = true
	_reload_t = 0.0
	_reload_duration = duration
	set_ads(false)
	set_precision_aim(false)


func _on_reloaded(_w: WeaponDefinition) -> void:
	_reload_active = false
	_reload_t = 0.0
	_weapon.reset_mag_transform()


func _on_weapon_switched(w: WeaponDefinition) -> void:
	if w == null:
		return
	_begin_switch(w.id)


func _begin_switch(id: StringName) -> void:
	if _weapon.weapon_id == id and not _switching:
		return
	_pending_weapon = id
	_switching = true
	_switch_t = 0.0
	set_ads(false)
	set_precision_aim(false)


func _sync_weapon_from_combatant() -> void:
	if _wc == null:
		return
	var w := _wc.current_weapon()
	if w:
		_weapon.set_weapon(w.id)


func _build_reload_animation() -> void:
	var lib := AnimationLibrary.new()
	var anim := Animation.new()
	anim.length = 2.5
	anim.loop_mode = Animation.LOOP_NONE
	lib.add_animation(&"reload_rifle", anim)
	_anim.add_animation_library(&"", lib)


func _skin_dict() -> Dictionary:
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return {}
	return gs.settings.get("skins", {})


func _quality_tier() -> int:
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return 2
	var q := String(gs.settings.get("quality", "high"))
	match q:
		"perf", "low":
			return 0
		"med", "medium":
			return 1
		_:
			return 2


func _player_is_crouching() -> bool:
	if _player == null:
		return false
	if _player.has_method("is_crouching"):
		return _player.is_crouching()
	return bool(_player.get_meta("crouching", false))


func _player_is_alive() -> bool:
	if _player == null:
		return true
	var c := _player.get_node_or_null("Combatant") as Combatant
	return c == null or c.alive


func _gs_setting(key: String, default_val: Variant) -> Variant:
	var gs = get_node_or_null("/root/GameState")
	if gs == null:
		return default_val
	return gs.settings.get(key, default_val)
