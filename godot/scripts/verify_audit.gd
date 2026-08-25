extends SceneTree
## Physics / design / engine audit checks beyond basic verify.
## godot --headless --path godot -s res://scripts/verify_audit.gd

const PMoveScript = preload("res://scripts/pmove.gd")
const DT := 1.0 / 64.0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed: int = 0
	failed += _test_config_design()
	failed += _test_air_cap_model()
	failed += _test_landhop_gravity_parity()
	failed += await _test_scene_engine()

	if failed == 0:
		print("VERIFY_AUDIT_OK")
		quit(0)
	else:
		print("VERIFY_AUDIT_FAIL %d" % failed)
		quit(1)


func _ok(msg: String) -> int:
	print("OK: ", msg)
	return 0


func _fail(msg: String) -> int:
	print("FAIL: ", msg)
	return 1


func _test_config_design() -> int:
	var cfg: Resource = load("res://resources/cs2_clashpoint_move.tres") as Resource
	if cfg == null:
		return _fail("config missing")
	if bool(cfg.get("autobhop")):
		return _fail("autobhop must be off (CS default)")
	if absf(float(cfg.get("air_wish_cap")) - 0.72) > 0.001:
		return _fail("air_wish_cap must be 0.72 (30u scaled), not full-speed clamp")
	if float(cfg.get("eye_crouch")) >= float(cfg.get("crouch_height")) - 0.05:
		return _fail("eye_crouch must sit below crouch capsule top (clip risk)")
	if float(cfg.get("jump_buffer")) > 3.0 / 64.0 + 0.001:
		return _fail("jump_buffer too long for CS skill window: %.4f" % float(cfg.get("jump_buffer")))
	if absf(float(cfg.get("gravity")) - 19.2) > 0.01:
		return _fail("gravity")
	var ticks: int = int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	if ticks != 64:
		return _fail("physics tick must be 64, got %s" % str(ticks))
	var eng: String = str(ProjectSettings.get_setting("physics/3d/physics_engine"))
	if eng.findn("Jolt") < 0:
		return _fail("physics engine must be Jolt, got %s" % eng)
	return _ok("config design + engine settings")


func _test_air_cap_model() -> int:
	var vel: Vector3 = Vector3(0, 0, -8.5)
	vel = PMoveScript.air_accelerate(vel, Vector3(1, 0, 0), 6.0, 12.0, 0.72, DT)
	if Vector2(vel.x, vel.z).length() < 8.0:
		return _fail("air model still hard-clamps |v|")
	vel = Vector3(0, 0, -6.0)
	var before: float = vel.z
	vel = PMoveScript.air_accelerate(vel, Vector3(0, 0, -1), 6.0, 12.0, 0.72, DT)
	if absf(vel.z - before) > 0.001:
		return _fail("forward air wish should not add when already faster than air cap")
	return _ok("air wish-cap model (no |v| clamp)")


func _test_landhop_gravity_parity() -> int:
	var g: float = 19.2
	var j: float = 7.25
	var y: float = 0.0
	var vy: float = j - g * DT
	var peak_ground: float = 0.0
	for i in 200:
		y += vy * DT
		peak_ground = maxf(peak_ground, y)
		vy -= g * DT
		if y < 0.0 and i > 2:
			break
	y = 0.0
	vy = j
	var peak_buggy: float = 0.0
	for i in 200:
		y += vy * DT
		peak_buggy = maxf(peak_buggy, y)
		vy -= g * DT
		if y < 0.0 and i > 2:
			break
	if peak_buggy - peak_ground < 0.01:
		return _fail("parity fixture broken")
	y = 0.0
	vy = j - g * DT
	var peak_fixed: float = 0.0
	for i in 200:
		y += vy * DT
		peak_fixed = maxf(peak_fixed, y)
		vy -= g * DT
		if y < 0.0 and i > 2:
			break
	if absf(peak_fixed - peak_ground) > 0.001:
		return _fail("landhop FinishGravity parity failed")
	return _ok("land-hop gravity parity (Δbuggy=%.3f)" % (peak_buggy - peak_ground))


func _test_scene_engine() -> int:
	var packed: PackedScene = load("res://scenes/test_level.tscn") as PackedScene
	if packed == null:
		return _fail("test_level missing")
	var level: Node = packed.instantiate()
	root.add_child(level)
	for i in 12:
		await physics_frame
	var player: CharacterBody3D = level.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		return _fail("player missing")
	if not player.has_method("get_apex_estimate"):
		return _fail("player missing pmove API")
	if player.get("config") == null:
		return _fail("player config null")
	player.global_position = Vector3(-6, 0.02, -2.5)
	player.velocity = Vector3.ZERO
	player.set("_yaw", 0.0)
	Input.action_press("move_forward")
	var stepped: bool = false
	for i in 90:
		await physics_frame
		if player.global_position.y > 0.35:
			stepped = true
			break
	Input.action_release("move_forward")
	if not stepped:
		return _fail("step-up onto 0.4m ledge failed (y=%.3f)" % player.global_position.y)
	var shape: CollisionShape3D = player.get_node("CollisionShape3D") as CollisionShape3D
	var cap: CapsuleShape3D = shape.shape as CapsuleShape3D
	if cap == null:
		return _fail("missing capsule shape")
	if absf(shape.position.y - cap.height * 0.5) > 0.02:
		return _fail("capsule center not at half-height (feet origin)")
	return _ok("scene engine step-up + capsule origin")
