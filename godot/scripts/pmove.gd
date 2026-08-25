class_name PMove
extends RefCounted
## Quake/Source-style player movement math (meters).
## AirAccelerate caps wishspeed (not |v_xz|) — canonical CS airstrafe.

static func apply_friction(vel: Vector3, friction: float, stop_speed: float, dt: float) -> Vector3:
	var sp := Vector2(vel.x, vel.z).length()
	if sp < 0.01:
		vel.x = 0.0
		vel.z = 0.0
		return vel
	var control := stop_speed if sp < stop_speed else sp
	var drop := minf(sp, control * friction * dt)
	var ns := (sp - drop) / sp
	vel.x *= ns
	vel.z *= ns
	return vel


## Quake PM_Accelerate / Source Accelerate — ground.
static func accelerate(vel: Vector3, wish_dir: Vector3, wish_speed: float, accel: float, dt: float) -> Vector3:
	if wish_speed <= 0.0 or wish_dir.length_squared() < 1e-8:
		return vel
	var current := vel.x * wish_dir.x + vel.z * wish_dir.z
	var add_speed := wish_speed - current
	if add_speed <= 0.0:
		return vel
	var accel_speed := minf(add_speed, accel * wish_speed * dt)
	vel.x += wish_dir.x * accel_speed
	vel.z += wish_dir.z * accel_speed
	return vel


## Source AirAccelerate: clamp wishspeed to air_wish_cap (≈30 Source units),
## then accelerate. Does NOT hard-clamp total horizontal speed.
## Rate uses uncapped wish_speed (Valve gamemovement.cpp).
static func air_accelerate(
	vel: Vector3,
	wish_dir: Vector3,
	wish_speed: float,
	accel: float,
	air_wish_cap: float,
	dt: float
) -> Vector3:
	if wish_speed <= 0.0 or wish_dir.length_squared() < 1e-8:
		return vel
	var wishspd := minf(wish_speed, air_wish_cap)
	var current := vel.x * wish_dir.x + vel.z * wish_dir.z
	var add_speed := wishspd - current
	if add_speed <= 0.0:
		return vel
	var accel_speed := minf(add_speed, accel * wish_speed * dt)
	vel.x += wish_dir.x * accel_speed
	vel.z += wish_dir.z * accel_speed
	return vel


static func clamp_max_velocity(vel: Vector3, max_vel: float) -> Vector3:
	var sp := vel.length()
	if sp > max_vel and sp > 0.0:
		return vel * (max_vel / sp)
	return vel


static func wish_from_input(forward: Vector3, right: Vector3, input: Vector2) -> Vector3:
	## input: x = strafe (-1..1), y = forward (-1..1) from Input.get_vector(left,right,back,forward)
	var wish := forward * input.y + right * input.x
	wish.y = 0.0
	if wish.length_squared() > 1e-8:
		wish = wish.normalized()
	return wish
