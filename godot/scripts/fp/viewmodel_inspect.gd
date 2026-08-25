class_name ViewModelInspect
extends SubViewportContainer
## Inventory / lobby 3D weapon preview — reuses ViewModelWeapon mesh builder.

const ViewModelWeaponScript := preload("res://scripts/fp/viewmodel_weapon.gd")

@export var weapon_id: StringName = &"ak"
@export var team: WeaponDefinition.Team = WeaponDefinition.Team.CT

var _weapon: Node3D
var _orbit: float = 0.0


func _ready() -> void:
	stretch = true
	var vp := SubViewport.new()
	vp.transparent_bg = true
	vp.handle_input_locally = false
	add_child(vp)

	var cam := Camera3D.new()
	cam.position = Vector3(0.35, -0.05, 0.55)
	cam.rotation = Vector3(-0.15, 0.55, 0)
	cam.fov = 55.0
	cam.current = true
	vp.add_child(cam)

	var light := DirectionalLight3D.new()
	light.rotation = Vector3(-0.8, 0.6, 0)
	light.light_energy = 1.4
	vp.add_child(light)

	var fill := OmniLight3D.new()
	fill.position = Vector3(-0.4, 0.2, 0.3)
	fill.light_energy = 0.6
	vp.add_child(fill)

	_weapon = ViewModelWeaponScript.new()
	_weapon.name = "InspectWeapon"
	vp.add_child(_weapon)
	if _weapon.has_method("setup"):
		_weapon.setup(team, {})
	if _weapon.has_method("set_weapon"):
		_weapon.set_weapon(weapon_id)
	_weapon.rotation.y = 0.35


func _process(delta: float) -> void:
	_orbit += delta * 0.25
	if _weapon:
		_weapon.rotation.y = 0.35 + sin(_orbit) * 0.08


func set_weapon(id: StringName) -> void:
	weapon_id = id
	if _weapon:
		_weapon.set_weapon(id)
