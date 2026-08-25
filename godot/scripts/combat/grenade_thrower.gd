class_name GrenadeThrower
extends Node
## Spawns grenade projectile from camera. Keys 4/5/6/7 = HE/flash/smoke/molotov.

@export var camera_path: NodePath = NodePath("Head/Camera3D")
var camera: Camera3D
var owner_combatant: Combatant


func _ready() -> void:
	camera = get_node_or_null(camera_path) as Camera3D
	owner_combatant = get_parent().get_node_or_null("Combatant") as Combatant


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_4:
				throw_grenade(Grenade.Kind.HE)
			KEY_5:
				throw_grenade(Grenade.Kind.FLASH)
			KEY_6:
				throw_grenade(Grenade.Kind.SMOKE)
			KEY_7:
				throw_grenade(Grenade.Kind.MOLOTOV)


func throw_grenade(kind: Grenade.Kind) -> void:
	if camera == null:
		camera = get_node_or_null(camera_path) as Camera3D
	if camera == null:
		return
	var g := Grenade.new()
	g.kind = kind
	g.thrower = owner_combatant
	var cs := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.12
	cs.shape = sph
	g.add_child(cs)
	g.mass = 0.4
	g.gravity_scale = 1.0
	var root := get_tree().current_scene
	if root == null:
		return
	root.add_child(g)
	var origin := camera.global_position + (-camera.global_transform.basis.z) * 0.4
	g.launch(origin, -camera.global_transform.basis.z, 18.0)
	if has_node("/root/AudioBus"):
		AudioBus.play_sfx(&"shoot")
