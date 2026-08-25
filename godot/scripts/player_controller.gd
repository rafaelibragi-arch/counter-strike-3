class_name PlayerController
extends CharacterBody3D
## Clashpoint FPS body: Source pmove + CharacterBody3D collision (Jolt).
## Feet at origin. Capsule height changes for crouch. Ceiling clips vel.y.

@export var config: MoveConfig

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var hud: CanvasLayer = $HUD
@onready var viewmodel: Node3D = $Head/Camera3D/ViewModel

var _yaw: float = 0.0
var _pitch: float = 0.0
var _crouching: bool = false
var _want_crouch: bool = false
var _jump_buf: float = 0.0
var _jump_held: bool = false
var _on_ground: bool = true
var _capsule: CapsuleShape3D
var _eye_height: float = 1.7
var _debug_label: Label
var _last_vy: float = 0.0
var _viewmodel: Node3D

const FLOOR_SNAP := 0.12
const CEILING_NORMAL_Y := -0.7
const DUCK_EYE_SPEED := 11.0
const DUCK_COL_SPEED := 22.0
const STEP_LIFT := 0.02


func _ready() -> void:
	if config == null:
		config = load("res://resources/cs2_clashpoint_move.tres") as MoveConfig
	_capsule = collision_shape.shape as CapsuleShape3D
	if _capsule == null:
		_capsule = CapsuleShape3D.new()
		collision_shape.shape = _capsule
	_apply_capsule(false)
	_eye_height = config.eye_standing
	head.position.y = _eye_height
	floor_snap_length = FLOOR_SNAP
	floor_max_angle = deg_to_rad(46.0)
	floor_constant_speed = true
	floor_block_on_wall = true
	safe_margin = 0.04
	up_direction = Vector3.UP
	motion_mode = MOTION_MODE_GROUNDED
	wall_min_slide_angle = deg_to_rad(15.0)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_debug_label = hud.get_node_or_null("DebugLabel") as Label
	_viewmodel = viewmodel
	if _viewmodel:
		if "player_path" in _viewmodel:
			_viewmodel.player_path = NodePath("../../..")
		if "camera_path" in _viewmodel:
			_viewmodel.camera_path = NodePath("..")
		if "weapon_controller_path" in _viewmodel:
			_viewmodel.weapon_controller_path = NodePath("../../../WeaponController")
	ProjectSettings.set_setting("physics/3d/default_gravity", config.gravity)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * config.mouse_sensitivity
		_pitch -= mm.relative.y * config.mouse_sensitivity
		_pitch = clampf(_pitch, -config.max_pitch, config.max_pitch)
		rotation.y = _yaw
		head.rotation.x = _pitch
	if event.is_action_pressed("toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _viewmodel:
		if event.is_action_pressed("aim"):
			_viewmodel.set_ads(true)
		if event.is_action_released("aim"):
			_viewmodel.set_ads(false)
		if event.is_action_pressed("precision_aim"):
			_viewmodel.set_precision_aim(true)
		if event.is_action_released("precision_aim"):
			_viewmodel.set_precision_aim(false)


func _physics_process(dt: float) -> void:
	_last_vy = velocity.y
	set_meta("last_vy", _last_vy)
	set_meta("crouching", _crouching)
	_want_crouch = Input.is_action_pressed("crouch")
	_update_crouch()

	var was_on_floor := is_on_floor()
	_on_ground = was_on_floor

	# Jump buffer: edge press; autobhop refreshes while held in air
	var space_down := Input.is_action_pressed("jump")
	var jump_edge := space_down and not _jump_held
	_jump_held = space_down
	if jump_edge:
		_jump_buf = config.jump_buffer
	elif config.autobhop and space_down and not _on_ground:
		_jump_buf = config.jump_buffer

	# Wish direction from camera yaw (horizontal)
	var input_vec := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var input_mag := clampf(input_vec.length(), 0.0, 1.0)
	var forward := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	var right := Vector3(cos(_yaw), 0.0, -sin(_yaw))
	var wish := PMove.wish_from_input(forward, right, input_vec)

	var wish_speed := config.walk_speed if Input.is_action_pressed("walk") else config.run_speed
	if _crouching:
		wish_speed *= config.crouch_mul
	# Analog stick: scale wishspeed by input magnitude (keyboard get_vector is unit length)
	wish_speed *= input_mag

	# Source order: jump this frame skips friction (bhop). Else friction → accel.
	var hopped := false
	if _on_ground and _jump_buf > 0.0:
		hopped = _try_jump()
		_jump_buf = 0.0

	if _on_ground and not hopped:
		velocity = PMove.apply_friction(velocity, config.friction, config.stop_speed, dt)
		velocity = PMove.accelerate(velocity, wish, wish_speed, config.ground_accel, dt)
	else:
		# Air / just-jumped: AirAccelerate with wishspeed cap (NOT |v| hard clamp)
		velocity = PMove.air_accelerate(
			velocity, wish, wish_speed, config.air_accel, config.air_wish_cap, dt
		)

	# Gravity after jump set (Source FinishGravity same tick)
	if get_meta("on_ladder", false):
		var climb: float = float(get_meta("ladder_speed", 3.5))
		var up := 0.0
		if Input.is_action_pressed("move_forward"):
			up += 1.0
		if Input.is_action_pressed("move_back"):
			up -= 1.0
		velocity.y = up * climb
		# still allow mild XZ
	elif not is_on_floor() or hopped:
		velocity.y -= config.gravity * dt
	elif velocity.y < 0.0:
		velocity.y = 0.0

	velocity = PMove.clamp_max_velocity(velocity, config.max_velocity)

	# Custom step-up (Jolt CharacterBody3D has no max_step_height)
	if is_on_floor() and not hopped and wish.length_squared() > 0.01:
		_try_step_up(wish, dt)

	floor_snap_length = 0.0 if hopped or not is_on_floor() else FLOOR_SNAP
	move_and_slide()

	# Ceiling: clip upward velocity when hitting overhead
	if is_on_ceiling() and velocity.y > 0.0:
		velocity.y = 0.0
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var n := col.get_normal()
		if n.y < CEILING_NORMAL_Y and velocity.y > 0.0:
			velocity.y = 0.0
			break

	# Land hop: same-frame jump before next tick's friction; FinishGravity for parity
	if not was_on_floor and is_on_floor() and not hopped:
		_on_ground = true
		if velocity.y < 0.0:
			velocity.y = 0.0
		if _jump_buf > 0.0:
			_try_jump()
			_jump_buf = 0.0
			velocity.y -= config.gravity * dt
			floor_snap_length = 0.0

	if _jump_buf > 0.0:
		_jump_buf = maxf(0.0, _jump_buf - dt)

	_update_eye(dt)
	_update_hud()


func _try_jump() -> bool:
	# Fixed-height CS-style jump (sets vy, does not add)
	velocity.y = config.jump_vel
	_on_ground = false
	floor_snap_length = 0.0
	return true


## Probe ahead: if a ledge ≤ step_height blocks XZ but is clear above, lift onto it.
func _try_step_up(wish: Vector3, dt: float) -> void:
	var space := get_world_3d().direct_space_state
	if space == null:
		return
	var step := config.step_height
	var radius := config.capsule_radius
	var dir := Vector3(wish.x, 0.0, wish.z).normalized()
	# Must reach past capsule radius — when blocked, move_and_slide zeroes speed
	var probe_dist := maxf(radius + 0.2, Vector2(velocity.x, velocity.z).length() * dt + radius * 0.5)
	var from := global_position + Vector3(0, 0.08, 0)
	var low_to := from + dir * probe_dist

	var low := PhysicsRayQueryParameters3D.create(from, low_to)
	low.collision_mask = 1
	low.exclude = [get_rid()]
	var low_hit := space.intersect_ray(low)
	if low_hit.is_empty():
		return

	var hit_pos: Vector3 = low_hit.position
	var top_start: Vector3 = hit_pos + dir * 0.05 + Vector3(0, step + 0.05, 0)
	var top_end: Vector3 = Vector3(top_start.x, global_position.y - 0.05, top_start.z)
	var down := PhysicsRayQueryParameters3D.create(top_start, top_end)
	down.collision_mask = 1
	down.exclude = [get_rid()]
	var top_hit := space.intersect_ray(down)
	if top_hit.is_empty():
		return
	var top_pos: Vector3 = top_hit.position
	var rise: float = top_pos.y - global_position.y
	if rise <= 0.04 or rise > step:
		return

	var dest := Vector3(top_pos.x, top_pos.y + STEP_LIFT, top_pos.z)
	var head_q := PhysicsRayQueryParameters3D.create(
		dest + Vector3(0, 0.1, 0),
		dest + Vector3(0, _capsule.height + 0.05, 0)
	)
	head_q.collision_mask = 1
	head_q.exclude = [get_rid()]
	if not space.intersect_ray(head_q).is_empty():
		return

	global_position = dest
	velocity.y = 0.0


func _update_crouch() -> void:
	var want := _want_crouch
	if not want and _headroom_blocked():
		want = true
	_crouching = want
	_apply_capsule(_crouching)


func _apply_capsule(crouched: bool) -> void:
	var target_h := config.crouch_height if crouched else config.standing_height
	var radius := config.capsule_radius
	# Godot 4.7 CapsuleShape3D.height is TOTAL height (incl. hemispheres)
	_capsule.radius = radius
	_capsule.height = maxf(radius * 2.0 + 0.01, target_h)
	collision_shape.position.y = _capsule.height * 0.5


func _headroom_blocked() -> bool:
	var space := get_world_3d().direct_space_state
	if space == null:
		return false
	var radius := config.capsule_radius * 0.9
	var from_y := config.crouch_height - radius
	var to_y := config.standing_height - radius
	var q := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	q.shape = sphere
	q.transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, from_y, 0))
	q.motion = Vector3(0, to_y - from_y, 0)
	q.collision_mask = 1
	q.exclude = [get_rid()]
	var hit: PackedFloat32Array = space.cast_motion(q)
	return hit.size() >= 1 and hit[0] < 0.999


func _update_eye(dt: float) -> void:
	var target := config.eye_crouch if _crouching else config.eye_standing
	var sp := DUCK_COL_SPEED if _crouching else DUCK_EYE_SPEED
	_eye_height = lerpf(_eye_height, target, minf(1.0, dt * sp))
	head.position.y = _eye_height


func _update_hud() -> void:
	if _debug_label == null:
		return
	var sp := Vector2(velocity.x, velocity.z).length()
	_debug_label.text = (
		"Clashpoint PMove (Source/CS2)\n"
		+ "speed xz: %.2f m/s  (run=%.1f)\n" % [sp, config.run_speed]
		+ "vel.y: %.2f\n" % velocity.y
		+ "on_floor: %s  crouch: %s\n" % [str(is_on_floor()), str(_crouching)]
		+ "jump_buf: %.3f  autobhop: %s\n" % [_jump_buf, str(config.autobhop)]
		+ "air_wish_cap: %.2f  (Source 30u)\n" % config.air_wish_cap
		+ "pos: (%.1f, %.2f, %.1f)\n" % [global_position.x, global_position.y, global_position.z]
		+ "WASD move | Shift walk | Ctrl crouch | Space jump | Esc mouse"
	)


func get_horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func is_crouching() -> bool:
	return _crouching


func get_eye_height() -> float:
	return _eye_height


func get_apex_estimate() -> float:
	return (config.jump_vel * config.jump_vel) / (2.0 * config.gravity)
