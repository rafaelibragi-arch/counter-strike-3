class_name ViewModelSkin
extends RefCounted
## Resolves equipped skin / glove colors for FP viewmodel.

const DEFAULT_GLOVE := Color(0.29, 0.16, 0.13)
const DEFAULT_WEAPON := Color(0.4, 0.4, 0.42)

static var _skin_table: Dictionary = {
	&"ak": Color(0.55, 0.35, 0.18),
	&"m4": Color(0.22, 0.45, 0.72),
	&"awp": Color(0.18, 0.22, 0.28),
	&"knife": Color(0.75, 0.75, 0.78),
	&"glock": Color(0.35, 0.35, 0.38),
	&"usps": Color(0.28, 0.32, 0.36),
	&"deagle": Color(0.62, 0.48, 0.22),
}


static func glove_color(settings: Dictionary = {}) -> Color:
	if settings.has("equipped_gloves_color"):
		return Color.from_string(String(settings.equipped_gloves_color), DEFAULT_GLOVE)
	return DEFAULT_GLOVE


static func weapon_color(weapon_id: StringName, settings: Dictionary = {}) -> Color:
	var key := "equipped_%s_color" % String(weapon_id)
	if settings.has(key):
		return Color.from_string(String(settings[key]), DEFAULT_WEAPON)
	if _skin_table.has(weapon_id):
		return _skin_table[weapon_id]
	return DEFAULT_WEAPON


static func clearcoat_for_rarity(rarity: String) -> float:
	match rarity:
		"covert", "gold":
			return 0.9
		"classified", "restricted":
			return 0.65
		_:
			return 0.35


static func apply_paint_to_mesh(root: Node3D, color: Color, rarity: String = "milspec") -> void:
	var cc := clearcoat_for_rarity(rarity)
	_apply_recursive(root, color, cc)


static func _apply_recursive(node: Node, color: Color, clearcoat: float) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.name == "mag":
			return
		var src := mi.material_override as StandardMaterial3D
		if src == null:
			src = StandardMaterial3D.new()
		var dup := src.duplicate() as StandardMaterial3D
		dup.albedo_color = color if node.name.begins_with("Weapon") or node.get_parent().name.begins_with("Weapon") else dup.albedo_color
		if clearcoat > 0.01 and not node.name.begins_with("Right") and not node.name.begins_with("Left"):
			dup.clearcoat = clearcoat
		mi.material_override = dup
	for child in node.get_children():
		_apply_recursive(child, color, clearcoat)
