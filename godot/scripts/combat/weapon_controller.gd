class_name WeaponController
extends Node
## Player hitscan shooter: Camera3D raycast, mag/reserve/reload/recoil.

const SprayPatternsLib := preload("res://weapons/spray_patterns.gd")

signal shot_fired(weapon: WeaponDefinition)
signal reloaded(weapon: WeaponDefinition)
signal reload_started(weapon: WeaponDefinition, duration: float)
signal weapon_switched(weapon: WeaponDefinition)
signal hit_confirmed(target: Combatant, damage: float, hitgroup: StringName)

@export var camera_path: NodePath
@export var combatant_path: NodePath
@export var recoil_node_path: NodePath ## usually Head / camera parent
@export var max_range: float = 500.0
@export var collision_mask: int = 0xFFFFFFFF

var camera: Camera3D
var combatant: Combatant
var recoil_node: Node3D

var mag: int = 0
var reserve_ammo: int = 0
var spray_index: int = 0
var recoil_pitch: float = 0.0
var spray_timer: float = 0.0

var _fire_cd: float = 0.0
var _reloading: bool = false
var _reload_left: float = 0.0
var _was_fire: bool = false


func _ready() -> void:
	camera = get_node_or_null(camera_path) as Camera3D
	combatant = get_node_or_null(combatant_path) as Combatant
	recoil_node = get_node_or_null(recoil_node_path) as Node3D
	if camera == null:
		camera = _find_camera(get_parent())
	if combatant == null:
		var p := get_parent()
		combatant = p.get_node_or_null("Combatant") as Combatant
		if combatant == null and p is Combatant:
			combatant = p as Combatant
	if recoil_node == null and camera:
		recoil_node = camera.get_parent() as Node3D
	_sync_ammo_from_weapon()


func _process(delta: float) -> void:
	if combatant and not combatant.alive:
		return
	_fire_cd = maxf(0.0, _fire_cd - delta)
	# Spray recovery (port of browser sprayTimer)
	if spray_timer > 0.0:
		spray_timer = maxf(0.0, spray_timer - delta)
	else:
		spray_index = maxi(0, spray_index - ceili(delta * 18.0))
	if _reloading:
		_reload_left -= delta
		if _reload_left <= 0.0:
			_finish_reload()

	var fire_held := false
	if InputMap.has_action("fire"):
		fire_held = Input.is_action_pressed("fire")
	else:
		fire_held = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	var fire_edge := fire_held and not _was_fire
	_was_fire = fire_held

	var w := current_weapon()
	if w == null:
		return
	var want_fire := fire_held if w.automatic else fire_edge
	if want_fire:
		try_fire()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:
				select_slot(WeaponDefinition.Slot.PRIMARY)
			KEY_2:
				select_slot(WeaponDefinition.Slot.SECONDARY)
			KEY_3:
				select_slot(WeaponDefinition.Slot.MELEE)
			KEY_R:
				start_reload()
	if event.is_action_pressed("reload"):
		start_reload()
	if event.is_action_pressed("weapon_1"):
		select_slot(WeaponDefinition.Slot.PRIMARY)
	elif event.is_action_pressed("weapon_2"):
		select_slot(WeaponDefinition.Slot.SECONDARY)
	elif event.is_action_pressed("weapon_3"):
		select_slot(WeaponDefinition.Slot.MELEE)


func current_weapon() -> WeaponDefinition:
	if combatant == null:
		return null
	return combatant.get_weapon(combatant.active_slot)


func try_fire() -> bool:
	if _reloading or _fire_cd > 0.0:
		return false
	var w := current_weapon()
	if w == null or combatant == null or not combatant.alive:
		return false
	if w.type == WeaponDefinition.Type.MELEE:
		return _fire_melee(w)
	if mag <= 0:
		start_reload()
		return false
	mag -= 1
	_fire_cd = w.fire_interval_ms / 1000.0
	_apply_recoil(w)
	spray_index = mini(spray_index + 1, 60)
	spray_timer = 0.22
	shot_fired.emit(w)
	if has_node("/root/AudioBus"):
		var bus = get_node("/root/AudioBus")
		if bus.has_method("play_sfx"):
			bus.play_sfx(&"shoot")
	for _i in maxi(1, w.pellets):
		_hitscan(w)
	return true


func start_reload() -> void:
	var w := current_weapon()
	if w == null or _reloading:
		return
	if w.type == WeaponDefinition.Type.MELEE:
		return
	if mag >= w.mag_size or reserve_ammo <= 0:
		return
	_reloading = true
	_reload_left = w.reload_time
	reload_started.emit(w, w.reload_time)


func _finish_reload() -> void:
	_reloading = false
	var w := current_weapon()
	if w == null:
		return
	var need := w.mag_size - mag
	var take := mini(need, reserve_ammo)
	mag += take
	reserve_ammo -= take
	spray_index = 0
	reloaded.emit(w)


func select_slot(slot: WeaponDefinition.Slot) -> void:
	if combatant == null or not combatant.weapons.has(slot):
		return
	combatant.active_slot = slot
	_sync_ammo_from_weapon()
	spray_index = 0
	_reloading = false
	if combatant.weapons.has(slot):
		var w := combatant.get_weapon(slot)
		if w:
			weapon_switched.emit(w)


func _fire_melee(w: WeaponDefinition) -> bool:
	_fire_cd = w.fire_interval_ms / 1000.0
	shot_fired.emit(w)
	if camera == null:
		return false
	var origin := camera.global_position
	var dir := -camera.global_transform.basis.z.normalized()
	var hit := _ray(origin, dir, w.range_melee)
	if not hit.is_empty():
		_damage_hit(w, hit)
	return true


func _hitscan(w: WeaponDefinition) -> void:
	if camera == null:
		return
	var origin := camera.global_position
	var forward := -camera.global_transform.basis.z.normalized()
	var pattern: Array = SprayPatternsLib.for_weapon(w.id)
	var shot_i: int = mini(maxi(spray_index - 1, 0), pattern.size() - 1)
	var yaw := 0.0
	var pitch := 0.0
	if pattern.size() > 0:
		var p: Array = pattern[shot_i]
		yaw = float(p[0])
		pitch = float(p[1])
	var spray_scale := 0.012
	var parent_body := get_parent() as CharacterBody3D
	if parent_body and parent_body.is_on_floor() == false:
		spray_scale *= 1.35
	var crouching := parent_body != null and bool(parent_body.get_meta("crouching", false))
	if crouching:
		spray_scale *= 0.7
	var spread := w.spread * (1.0 + spray_index * 0.05)
	var right := camera.global_transform.basis.x.normalized()
	var up := camera.global_transform.basis.y.normalized()
	var dir := (
		forward
		+ right * (yaw * spray_scale + randf_range(-spread, spread))
		+ up * (pitch * spray_scale * 0.12 + randf_range(-spread * 0.8, spread * 0.8))
	).normalized()
	var hit := _ray(origin, dir, max_range)
	if not hit.is_empty():
		_damage_hit(w, hit)


func _damage_hit(w: WeaponDefinition, hit: Dictionary) -> void:
	var collider: Object = hit.get("collider")
	if collider == null:
		return
	var target := _find_combatant(collider as Node)
	if target == null or target == combatant or not target.alive:
		return
	if combatant and target.team == combatant.team and target.team != WeaponDefinition.Team.BOTH:
		return
	var hitgroup := &"chest"
	var n := collider as Node
	if n:
		var nm := String(n.name)
		if "Head" in nm or "head" in nm:
			hitgroup = &"head"
		elif "Leg" in nm or "leg" in nm:
			hitgroup = &"legs"
		elif "Stomach" in nm or "stomach" in nm:
			hitgroup = &"stomach"
	# Height heuristic when ray hits body capsule
	if hitgroup == &"chest" and hit.has("position") and target.get_parent() is Node3D:
		var root3 := target.get_parent() as Node3D
		var local_y: float = (hit["position"] as Vector3).y - root3.global_position.y
		if local_y > 1.45:
			hitgroup = &"head"
		elif local_y < 0.55:
			hitgroup = &"legs"
		elif local_y > 0.95 and local_y < 1.25:
			hitgroup = &"stomach"
	var dmg := target.apply_damage(w.damage, hitgroup, w.armor_pen, combatant)
	hit_confirmed.emit(target, dmg, hitgroup)
	if not target.alive and combatant:
		combatant.add_money(Economy.award_kill(w))


func _ray(origin: Vector3, dir: Vector3, length: float) -> Dictionary:
	var space := camera.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * length)
	q.collision_mask = collision_mask
	q.exclude = _exclude_self()
	return space.intersect_ray(q)


func _exclude_self() -> Array[RID]:
	var out: Array[RID] = []
	var root := get_parent()
	if root is CollisionObject3D:
		out.append((root as CollisionObject3D).get_rid())
	return out


func _apply_recoil(w: WeaponDefinition) -> void:
	var pattern: Array = SprayPatternsLib.for_weapon(w.id)
	var shot_i: int = mini(spray_index, maxi(pattern.size() - 1, 0))
	var pitch_kick := w.recoil * 0.018
	var yaw_kick := 0.0
	if pattern.size() > 0:
		var p: Array = pattern[shot_i]
		yaw_kick = float(p[0])
		pitch_kick += float(p[1]) * 0.012 * 0.35
	recoil_pitch += pitch_kick * 60.0
	if recoil_node:
		recoil_node.rotation.x -= pitch_kick * 0.02
		recoil_node.rotation.y += yaw_kick * 0.0008


func _sync_ammo_from_weapon() -> void:
	var w := current_weapon()
	if w == null or w.type == WeaponDefinition.Type.MELEE:
		mag = 0
		reserve_ammo = 0
		return
	mag = w.mag_size
	reserve_ammo = w.reserve


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


func _find_camera(n: Node) -> Camera3D:
	if n == null:
		return null
	if n is Camera3D:
		return n as Camera3D
	for child in n.get_children():
		var found := _find_camera(child)
		if found:
			return found
	return null
