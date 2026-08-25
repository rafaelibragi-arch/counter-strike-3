class_name BotController
extends CharacterBody3D
## Simple bot: navigate toward target, shoot on LOS. Difficulty scales aim/react.

enum Difficulty { EASY, NORMAL, HARD }

@export var difficulty: Difficulty = Difficulty.NORMAL
@export var move_speed: float = 5.5
@export var target_path: NodePath
@export var weapon_id: StringName = &"ak"
@export var team: WeaponDefinition.Team = WeaponDefinition.Team.T

var target: Node3D
var combatant: Combatant
var nav_agent: NavigationAgent3D

var _fire_cd: float = 0.0
var _react_left: float = 0.0
var _weapon: WeaponDefinition
var _mag: int = 0
var _reserve: int = 0


func _ready() -> void:
	combatant = get_node_or_null("Combatant") as Combatant
	if combatant == null:
		combatant = Combatant.new()
		combatant.name = "Combatant"
		add_child(combatant)
	combatant.team = team
	combatant.give_weapon(weapon_id)
	combatant.give_weapon(&"knife")
	_weapon = WeaponCatalog.get_weapon(weapon_id)
	if _weapon:
		_mag = _weapon.mag_size
		_reserve = _weapon.reserve
	nav_agent = get_node_or_null("NavigationAgent3D") as NavigationAgent3D
	if target_path != NodePath():
		target = get_node_or_null(target_path) as Node3D
	_react_left = _react_delay()


func _physics_process(delta: float) -> void:
	if combatant and not combatant.alive:
		velocity = Vector3.ZERO
		return
	if target == null:
		target = _find_enemy()
	_fire_cd = maxf(0.0, _fire_cd - delta)
	_react_left = maxf(0.0, _react_left - delta)

	# Bomb carrier: push toward site A when live and no close fight
	if has_meta("has_bomb") and get_meta("has_bomb") and team == WeaponDefinition.Team.T:
		var site := get_parent().get_node_or_null("BombsiteA") as Node3D
		if site and (target == null or global_position.distance_to(target.global_position) > 18.0):
			_move_toward(site.global_position, delta)
			if not is_on_floor():
				velocity.y -= 19.2 * delta
			move_and_slide()
			if global_position.distance_to(site.global_position) < 2.5:
				_try_bot_plant(delta)
			return

	if target == null:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var dist := to_target.length()
	var has_los := _line_of_sight(target)

	if has_los and dist < 40.0 and _react_left <= 0.0:
		_face(target.global_position)
		_try_shoot()
		# strafe a bit when shooting
		if dist < 12.0:
			var side := global_transform.basis.x * sin(Time.get_ticks_msec() * 0.003)
			velocity = side * move_speed * 0.4
		else:
			velocity = to_target.normalized() * move_speed * 0.35
	else:
		_move_toward(target.global_position, delta)

	if not is_on_floor():
		velocity.y -= 19.2 * delta
	move_and_slide()


func _try_bot_plant(delta: float) -> void:
	var arena := get_parent()
	if arena == null:
		return
	var rm: RoundManager = arena.get("round_mgr") as RoundManager
	if rm == null or rm.state != RoundManager.State.LIVE:
		return
	if rm.tick_plant(delta):
		set_meta("has_bomb", false)
		arena.set("bomb_planted_pos", global_position)
		arena.set("has_bomb", false)


func _move_toward(pos: Vector3, _delta: float) -> void:
	var dest := pos
	if nav_agent:
		nav_agent.target_position = pos
		if not nav_agent.is_navigation_finished():
			dest = nav_agent.get_next_path_position()
	var dir := dest - global_position
	dir.y = 0.0
	if dir.length() > 0.1:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		_face(dest)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _try_shoot() -> void:
	if _weapon == null or _fire_cd > 0.0:
		return
	if _mag <= 0:
		_mag = mini(_weapon.mag_size, _reserve)
		_reserve = maxi(0, _reserve - _mag)
		_fire_cd = _weapon.reload_time
		return
	_mag -= 1
	_fire_cd = _weapon.fire_interval_ms / 1000.0

	var eye := global_position + Vector3.UP * 1.6
	var aim := target.global_position + Vector3.UP * 1.4
	var miss := _aim_error()
	aim += Vector3(randf_range(-miss, miss), randf_range(-miss * 0.5, miss * 0.5), randf_range(-miss, miss))
	var dir := (aim - eye).normalized()
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(eye, eye + dir * 200.0)
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return
	var col: Object = hit.get("collider")
	var victim := _find_combatant(col as Node)
	if victim == null or victim == combatant or not victim.alive:
		return
	if victim.team == combatant.team and victim.team != WeaponDefinition.Team.BOTH:
		return
	var hg := &"chest"
	if col is Node and ("Head" in (col as Node).name or "head" in (col as Node).name):
		hg = &"head"
	victim.apply_damage(_weapon.damage, hg, _weapon.armor_pen, combatant)


func _aim_error() -> float:
	match difficulty:
		Difficulty.EASY:
			return 1.2
		Difficulty.HARD:
			return 0.15
		_:
			return 0.45


func _react_delay() -> float:
	match difficulty:
		Difficulty.EASY:
			return 0.55
		Difficulty.HARD:
			return 0.12
		_:
			return 0.28


func _line_of_sight(node: Node3D) -> bool:
	var eye := global_position + Vector3.UP * 1.6
	var aim := node.global_position + Vector3.UP * 1.4
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(eye, aim)
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	var col: Object = hit.get("collider")
	return _find_combatant(col as Node) != null or (col is Node and (col as Node).is_ancestor_of(node))


func _face(pos: Vector3) -> void:
	var look := pos
	look.y = global_position.y
	if look.distance_to(global_position) > 0.05:
		look_at(look, Vector3.UP)


func _find_enemy() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for group_name in ["player", "players", "combatant"]:
		for n in get_tree().get_nodes_in_group(group_name):
			if n == self or not (n is Node3D):
				continue
			var c := (n as Node).get_node_or_null("Combatant") as Combatant
			if c == null and n is Combatant:
				c = n as Combatant
			if c and c.alive and c.team != team:
				var d := global_position.distance_to((n as Node3D).global_position)
				if d < best_d:
					best_d = d
					best = n as Node3D
	return best


func _find_combatant(node: Node) -> Combatant:
	var n := node
	while n:
		if n is Combatant:
			return n as Combatant
		var c := n.get_node_or_null("Combatant") as Combatant
		if c:
			return c
		n = n.get_parent()
	return null
