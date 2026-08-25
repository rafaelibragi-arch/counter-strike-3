class_name ViewModelWeapon
extends Node3D
## Swaps weapon mesh, tracks mag/muzzle nodes, applies skins.

const MeshFactory := preload("res://scripts/fp/viewmodel_mesh_factory.gd")
const SkinLib := preload("res://scripts/fp/viewmodel_skin.gd")
const PoseLib := preload("res://scripts/fp/viewmodel_pose_library.gd")

signal weapon_mesh_changed(weapon_id: StringName)

var weapon_id: StringName = &"ak"
var _weapon_root: Node3D
var _arms_root: Node3D
var _mag: Node3D
var _mag_base: Transform3D
var _muzzle: Node3D
var _team: WeaponDefinition.Team = WeaponDefinition.Team.CT
var _skin_settings: Dictionary = {}


func setup(team: WeaponDefinition.Team, skin_settings: Dictionary = {}) -> void:
	_team = team
	_skin_settings = skin_settings
	if _arms_root:
		_arms_root.queue_free()
	_arms_root = MeshFactory.build_arms(team, SkinLib.glove_color(skin_settings))
	add_child(_arms_root)
	set_weapon(&"ak")


func set_weapon(id: StringName) -> void:
	if weapon_id == id and _weapon_root:
		return
	weapon_id = id
	if _weapon_root:
		_weapon_root.queue_free()
		_weapon_root = null
		_mag = null
		_muzzle = null

	var col = SkinLib.weapon_color(id, _skin_settings)
	var rarity := String(_skin_settings.get("equipped_%s_rarity" % String(id), "milspec"))
	_weapon_root = MeshFactory.build_weapon(id, col)
	SkinLib.apply_paint_to_mesh(_weapon_root, col, rarity)
	_weapon_root.name = "WeaponRoot"
	add_child(_weapon_root)

	var pose = PoseLib.get_pose(id)
	_weapon_root.position = pose.weapon_pos
	_weapon_root.rotation = pose.weapon_rot

	if _arms_root:
		var rh := _arms_root.get_node_or_null("RightHand") as Node3D
		var lh := _arms_root.get_node_or_null("LeftHand") as Node3D
		if rh:
			rh.position = pose.right_hand_pos
			rh.rotation = pose.right_hand_rot
			rh.visible = true
		if lh:
			lh.position = pose.left_hand_pos
			lh.rotation = pose.left_hand_rot
			lh.visible = pose.show_left_hand

	_mag = _weapon_root.get_node_or_null("mag") as Node3D
	if _mag:
		_mag_base = _mag.transform
	else:
		_mag_base = Transform3D.IDENTITY
	_muzzle = _find_named(_weapon_root, "muzzle")
	weapon_mesh_changed.emit(id)


func apply_skin_settings(settings: Dictionary) -> void:
	_skin_settings = settings
	if _arms_root:
		var glove = SkinLib.glove_color(settings)
		_tint_gloves(_arms_root, glove)
	if _weapon_root:
		var col = SkinLib.weapon_color(weapon_id, settings)
		var rarity := String(settings.get("equipped_%s_rarity" % String(weapon_id), "milspec"))
		SkinLib.apply_paint_to_mesh(_weapon_root, col, rarity)


func get_muzzle_global() -> Vector3:
	if _muzzle:
		return _muzzle.global_position
	if _weapon_root:
		return _weapon_root.global_position + Vector3(0, 0, -0.5)
	return global_position


func reset_mag_transform() -> void:
	if _mag:
		_mag.transform = _mag_base


func get_mag() -> Node3D:
	return _mag


func get_mag_base() -> Transform3D:
	return _mag_base


func get_weapon_root() -> Node3D:
	return _weapon_root


func get_arms_root() -> Node3D:
	return _arms_root


func set_weapon_visible(on: bool) -> void:
	if _weapon_root:
		_weapon_root.visible = on


func _tint_gloves(node: Node, col: Color) -> void:
	if node is MeshInstance3D and (node.name.begins_with("Right") or node.name.begins_with("Left") or node.get_parent().name.ends_with("Hand")):
		var mi := node as MeshInstance3D
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.metallic = 0.12
		m.roughness = 0.78
		mi.material_override = m
	for child in node.get_children():
		_tint_gloves(child, col)


func _find_named(root: Node, nm: String) -> Node3D:
	if root.name == nm:
		return root as Node3D
	for child in root.get_children():
		var found := _find_named(child, nm)
		if found:
			return found
	return null
