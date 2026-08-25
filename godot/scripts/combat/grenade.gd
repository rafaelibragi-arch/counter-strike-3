class_name Grenade
extends RigidBody3D
## Throwable projectile: HE / flash / smoke / molotov.

enum Kind { HE, FLASH, SMOKE, MOLOTOV }

signal detonated(kind: Kind, position: Vector3)

@export var kind: Kind = Kind.HE
@export var fuse: float = 1.6
@export var throw_speed: float = 18.0
@export var he_radius: float = 4.5
@export var he_damage: float = 98.0
@export var thrower: Combatant

var _fuse_left: float = 1.6
var _alive: bool = true


func _ready() -> void:
	gravity_scale = 1.0 # project gravity 19.2
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 4
	_fuse_left = fuse
	if not freeze:
		pass


func launch(from: Vector3, direction: Vector3, speed: float = -1.0) -> void:
	global_position = from
	linear_velocity = direction.normalized() * (throw_speed if speed < 0.0 else speed)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	_fuse_left -= delta
	if _fuse_left <= 0.0:
		_detonate()


func _detonate() -> void:
	if not _alive:
		return
	_alive = false
	var pos := global_position
	detonated.emit(kind, pos)
	match kind:
		Kind.HE:
			_he_blast(pos)
		Kind.FLASH:
			pass # stub: blind nearby cameras
		Kind.SMOKE:
			_spawn_area_stub("SmokeCloud", pos, 6.0, 18.0)
		Kind.MOLOTOV:
			_spawn_area_stub("MolotovZone", pos, 3.5, 7.0)
	queue_free()


func _he_blast(pos: Vector3) -> void:
	var space := get_world_3d().direct_space_state
	# Query nearby collision objects via sphere shape
	var params := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = he_radius
	params.shape = sphere
	params.transform = Transform3D(Basis(), pos)
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var hits := space.intersect_shape(params, 32)
	for h in hits:
		var col: Object = h.get("collider")
		if col == null:
			continue
		var target := _find_combatant(col as Node)
		if target == null or not target.alive:
			continue
		var dist: float = pos.distance_to((col as Node3D).global_position) if col is Node3D else 0.0
		var falloff := 1.0 - clampf(dist / he_radius, 0.0, 1.0)
		var dmg := he_damage * falloff
		target.apply_damage(dmg, &"chest", 0.5, thrower)


func _spawn_area_stub(area_name: String, pos: Vector3, radius: float, lifetime: float) -> void:
	var area := Area3D.new()
	area.name = area_name
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	area.add_child(shape)
	var parent := get_tree().current_scene
	if parent:
		parent.add_child(area)
		area.global_position = pos
		get_tree().create_timer(lifetime).timeout.connect(area.queue_free)


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
