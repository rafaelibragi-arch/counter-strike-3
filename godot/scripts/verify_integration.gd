extends SceneTree
## Integration checks: load graybox, exercise player physics without mouse.
## godot --headless --path godot -s res://scripts/verify_integration.gd


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := 0
	var packed: PackedScene = load("res://scenes/test_level.tscn")
	if packed == null:
		printerr("FAIL: could not load test_level.tscn")
		quit(1)
		return

	var level: Node = packed.instantiate()
	root.add_child(level)
	for i in 10:
		await physics_frame

	var player := level.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		printerr("FAIL: Player missing")
		quit(1)
		return

	failed += await _test_grounded(player)
	failed += await _test_run_speed(player)
	failed += await _test_jump_apex(player)
	failed += await _test_ceiling_clip(player)
	failed += await _test_crouch_height(player)
	failed += await _test_duck_under(player)
	failed += await _test_autobhop_default(player)
	failed += await _test_walk_off_crate(player)
	failed += await _test_ramp(player)

	if failed == 0:
		print("VERIFY_INTEGRATION_OK")
		quit(0)
	else:
		print("VERIFY_INTEGRATION_FAIL %d" % failed)
		quit(1)


func _press(action: String, on: bool) -> void:
	if on:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _clear_move() -> void:
	for a in ["move_forward", "move_back", "move_left", "move_right", "jump", "crouch", "walk"]:
		_press(a, false)


func _ok(msg: String) -> int:
	print("OK: ", msg)
	return 0


func _fail(msg: String) -> int:
	print("FAIL: ", msg)
	return 1


func _test_grounded(player: CharacterBody3D) -> int:
	_clear_move()
	for i in 20:
		await physics_frame
	if not player.is_on_floor():
		return _fail("player not on floor at spawn (y=%.3f)" % player.global_position.y)
	if player.global_position.y < -0.05 or player.global_position.y > 0.15:
		return _fail("spawn feet y unexpected: %.3f" % player.global_position.y)
	return _ok("spawn grounded y=%.3f" % player.global_position.y)


func _test_run_speed(player: CharacterBody3D) -> int:
	_clear_move()
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(0, 0.02, 10)
	player.set("_yaw", 0.0)
	_press("move_forward", true)
	var max_sp := 0.0
	for i in 90:
		await physics_frame
		var sp: float = Vector2(player.velocity.x, player.velocity.z).length()
		max_sp = maxf(max_sp, sp)
	_clear_move()
	if max_sp < 5.7 or max_sp > 6.3:
		return _fail("run speed peak %.3f (want ~6)" % max_sp)
	return _ok("run speed peak=%.3f" % max_sp)


func _test_jump_apex(player: CharacterBody3D) -> int:
	_clear_move()
	player.velocity = Vector3.ZERO
	player.global_position = Vector3(0, 0.02, 12)
	player.set("_jump_held", false)
	player.set("_jump_buf", 0.0)
	for i in 15:
		await physics_frame
	if not player.is_on_floor():
		return _fail("jump setup not on floor y=%.3f" % player.global_position.y)
	var y0 := player.global_position.y
	player.set("_jump_buf", 0.08)
	var peak := y0
	for i in 90:
		await physics_frame
		peak = maxf(peak, player.global_position.y)
		if player.is_on_floor() and i > 8 and player.velocity.y <= 0.0:
			break
	var rise := peak - y0
	if rise < 1.15 or rise > 1.55:
		return _fail("jump rise %.3f (want ~1.37) y0=%.3f peak=%.3f" % [rise, y0, peak])
	return _ok("jump rise=%.3f (from y0=%.3f)" % [rise, y0])


func _test_ceiling_clip(player: CharacterBody3D) -> int:
	_clear_move()
	player.global_position = Vector3(0, 0.02, 8)
	player.velocity = Vector3.ZERO
	player.set("_jump_held", false)
	player.set("_jump_buf", 0.0)
	for i in 12:
		await physics_frame
	player.set("_jump_buf", 0.08)
	var max_y := 0.0
	for i in 70:
		await physics_frame
		max_y = maxf(max_y, player.global_position.y)
		if player.is_on_floor() and i > 12:
			break
	if max_y > 1.2:
		return _fail("head punched through ceiling, feet_y max=%.3f" % max_y)
	return _ok("ceiling contained feet_y max=%.3f" % max_y)


func _test_crouch_height(player: CharacterBody3D) -> int:
	_clear_move()
	player.global_position = Vector3(0, 0.02, 14)
	player.velocity = Vector3.ZERO
	for i in 10:
		await physics_frame
	var shape: CollisionShape3D = player.get_node("CollisionShape3D")
	var cap := shape.shape as CapsuleShape3D
	# Godot 4.7: height is total capsule height
	var stand_h := cap.height
	_press("crouch", true)
	for i in 12:
		await physics_frame
	var crouch_h := cap.height
	var crouched_flag: bool = bool(player.get("_crouching"))
	_press("crouch", false)
	for i in 12:
		await physics_frame
	if stand_h < 1.7 or stand_h > 1.95:
		return _fail("standing capsule height %.3f" % stand_h)
	if not crouched_flag:
		return _fail("crouch flag not set (h=%.3f)" % crouch_h)
	if crouch_h > 1.25 or crouch_h < 1.05:
		return _fail("crouch capsule height %.3f" % crouch_h)
	return _ok("capsule stand=%.2f crouch=%.2f" % [stand_h, crouch_h])


func _test_duck_under(player: CharacterBody3D) -> int:
	_clear_move()
	# Place already under DuckTunnel (slab underside ≈ 1.225), crouched
	player.global_position = Vector3(10, 0.02, 4)
	player.velocity = Vector3.ZERO
	_press("crouch", true)
	for i in 12:
		await physics_frame
	if not bool(player.get("_crouching")):
		return _fail("not crouching under tunnel")
	var shape: CollisionShape3D = player.get_node("CollisionShape3D")
	var cap := shape.shape as CapsuleShape3D
	if cap.height > 1.25:
		return _fail("capsule too tall under tunnel: %.3f" % cap.height)
	# Release crouch — headroom must keep duck
	_press("crouch", false)
	for i in 12:
		await physics_frame
	if not bool(player.get("_crouching")):
		return _fail("headroom did not keep crouch under tunnel")
	# Walk out toward +Z to clear tunnel, then stand
	player.set("_yaw", PI)  # +Z
	_press("move_forward", true)
	for i in 80:
		await physics_frame
		if player.global_position.z > 7.0:
			break
	_clear_move()
	for i in 15:
		await physics_frame
	if bool(player.get("_crouching")) and player.global_position.z > 7.0:
		return _fail("still forced crouch after leaving tunnel")
	return _ok("duck-under + headroom hold + stand outside")


func _test_autobhop_default(player: CharacterBody3D) -> int:
	var cfg = player.get("config")
	if cfg == null:
		return _fail("no config")
	if bool(cfg.autobhop):
		return _fail("autobhop should be OFF by default")
	return _ok("autobhop off")


func _test_walk_off_crate(player: CharacterBody3D) -> int:
	_clear_move()
	player.global_position = Vector3(4, 0.78, -4)
	player.velocity = Vector3.ZERO
	for i in 25:
		await physics_frame
	if player.global_position.y < 0.65:
		return _fail("failed to stand on crate (y=%.3f on_floor=%s)" % [
			player.global_position.y, player.is_on_floor()
		])
	player.set("_yaw", PI)
	_press("move_forward", true)
	for i in 100:
		await physics_frame
		if player.global_position.y < 0.25:
			break
	_clear_move()
	for i in 50:
		await physics_frame
	if player.global_position.y > 0.35:
		return _fail("did not walk off crate to floor (y=%.3f)" % player.global_position.y)
	return _ok("walk-off crate → floor y=%.3f" % player.global_position.y)


func _test_ramp(player: CharacterBody3D) -> int:
	_clear_move()
	# Ramp low end near x≈-16, high near x≈-8 — approach from low end toward +X
	player.global_position = Vector3(-16.5, 0.02, 0)
	player.velocity = Vector3.ZERO
	player.set("_yaw", -PI * 0.5)  # face +X
	_press("move_forward", true)
	var max_y := 0.0
	for i in 180:
		await physics_frame
		max_y = maxf(max_y, player.global_position.y)
	_clear_move()
	if max_y < 0.4:
		return _fail("did not climb ramp (max_y=%.3f pos=%s)" % [max_y, player.global_position])
	return _ok("ramp climb max_y=%.3f" % max_y)
