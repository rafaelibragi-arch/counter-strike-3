extends SceneTree
## Headless verification of PMove math + simulated jump apex.
## Run: godot --headless --path godot -s res://scripts/verify_pmove.gd

const EPS := 0.08
const PMoveScript = preload("res://scripts/pmove.gd")


func _init() -> void:
	var failed := 0
	failed += _test_friction()
	failed += _test_ground_accel_caps_at_wish()
	failed += _test_air_wish_cap_not_speed_clamp()
	failed += _test_airstrafe_gains_speed()
	failed += _test_jump_apex()
	failed += _test_diagonal_not_faster()
	failed += _test_config_loads()

	if failed == 0:
		print("VERIFY_OK all pmove checks passed")
		quit(0)
	else:
		print("VERIFY_FAIL %d check(s) failed" % failed)
		quit(1)


func _fail(msg: String) -> int:
	print("FAIL: ", msg)
	return 1


func _ok(msg: String) -> int:
	print("OK: ", msg)
	return 0


func _test_friction() -> int:
	var vel := Vector3(6, 0, 0)
	vel = PMoveScript.apply_friction(vel, 5.2, 1.92, 1.0 / 64.0)
	var sp := Vector2(vel.x, vel.z).length()
	if sp >= 6.0 or sp < 5.0:
		return _fail("friction drop unexpected: %.4f" % sp)
	vel = Vector3(1.0, 0, 0)
	for i in 200:
		vel = PMoveScript.apply_friction(vel, 5.2, 1.92, 1.0 / 64.0)
	sp = Vector2(vel.x, vel.z).length()
	if sp > 0.05:
		return _fail("friction did not stop: %.4f" % sp)
	return _ok("ground friction")


func _test_ground_accel_caps_at_wish() -> int:
	var vel := Vector3.ZERO
	var wish := Vector3(0, 0, -1)
	var dt := 1.0 / 64.0
	for i in 200:
		vel = PMoveScript.apply_friction(vel, 5.2, 1.92, dt)
		vel = PMoveScript.accelerate(vel, wish, 6.0, 5.5, dt)
	var sp := Vector2(vel.x, vel.z).length()
	if absf(sp - 6.0) > EPS:
		return _fail("ground speed not ~6: %.4f" % sp)
	return _ok("ground accel → run 6 m/s (got %.3f)" % sp)


func _test_air_wish_cap_not_speed_clamp() -> int:
	var vel := Vector3(0, 0, -7.0)
	var wish := Vector3(1, 0, 0)
	var before := Vector2(vel.x, vel.z).length()
	vel = PMoveScript.air_accelerate(vel, wish, 6.0, 12.0, 0.72, 1.0 / 64.0)
	var after := Vector2(vel.x, vel.z).length()
	if vel.x <= 0.0:
		return _fail("airstrafe did not add lateral vel")
	if after < before - 0.5:
		return _fail("air accel wrongly destroyed speed: %.3f → %.3f" % [before, after])
	vel = Vector3(0, 0, -8.5)
	var sp0 := Vector2(vel.x, vel.z).length()
	vel = PMoveScript.air_accelerate(vel, wish, 6.0, 12.0, 0.72, 1.0 / 64.0)
	var sp1 := Vector2(vel.x, vel.z).length()
	if sp1 < 8.0:
		return _fail("hard speed clamp detected (old bug): %.3f → %.3f" % [sp0, sp1])
	return _ok("air wish cap (no |v| hard clamp), sp %.3f→%.3f" % [sp0, sp1])


func _test_airstrafe_gains_speed() -> int:
	var vel := Vector3(0, 0, -6.0)
	var dt := 1.0 / 64.0
	var yaw := 0.0
	for i in 40:
		yaw += 0.04
		var right := Vector3(cos(yaw), 0, -sin(yaw))
		vel = PMoveScript.air_accelerate(vel, right, 6.0, 12.0, 0.72, dt)
	var sp := Vector2(vel.x, vel.z).length()
	if sp < 6.0:
		return _fail("airstrafe lost speed: %.3f" % sp)
	if sp > 20.0:
		return _fail("airstrafe unbounded (too much): %.3f" % sp)
	return _ok("airstrafe chain speed=%.3f" % sp)


func _test_jump_apex() -> int:
	var jump_vel := 7.25
	var gravity := 19.2
	var expected := (jump_vel * jump_vel) / (2.0 * gravity)
	var y := 0.0
	var vy := jump_vel
	var dt := 1.0 / 64.0
	var peak := 0.0
	vy -= gravity * dt
	for i in 200:
		y += vy * dt
		peak = maxf(peak, y)
		vy -= gravity * dt
		if y < 0.0 and i > 2:
			break
	if absf(expected - 1.37) > 0.05:
		return _fail("expected apex formula off: %.3f" % expected)
	if peak < 1.2 or peak > 1.45:
		return _fail("sim apex out of range: %.3f (theory %.3f)" % [peak, expected])
	return _ok("jump apex sim=%.3f theory=%.3f" % [peak, expected])


func _test_diagonal_not_faster() -> int:
	var forward := Vector3(0, 0, -1)
	var right := Vector3(1, 0, 0)
	var wish: Vector3 = PMoveScript.wish_from_input(forward, right, Vector2(1, 1))
	if absf(wish.length() - 1.0) > 0.01:
		return _fail("diagonal wish not normalized: %.3f" % wish.length())
	var vel := Vector3.ZERO
	var dt := 1.0 / 64.0
	for i in 200:
		vel = PMoveScript.apply_friction(vel, 5.2, 1.92, dt)
		vel = PMoveScript.accelerate(vel, wish, 6.0, 5.5, dt)
	var sp := Vector2(vel.x, vel.z).length()
	if absf(sp - 6.0) > EPS:
		return _fail("diagonal speed %.3f != 6" % sp)
	return _ok("diagonal wish normalized, speed=%.3f" % sp)


func _test_config_loads() -> int:
	var cfg = load("res://resources/cs2_clashpoint_move.tres")
	if cfg == null:
		return _fail("cs2_clashpoint_move.tres failed to load")
	if absf(float(cfg.run_speed) - 6.0) > 0.001:
		return _fail("run_speed")
	if absf(float(cfg.air_wish_cap) - 0.72) > 0.001:
		return _fail("air_wish_cap should be 0.72 not full-speed clamp")
	if bool(cfg.autobhop):
		return _fail("autobhop must default OFF")
	if absf(float(cfg.gravity) - 19.2) > 0.001:
		return _fail("gravity")
	return _ok("MoveConfig CS2 Clashpoint preset")
