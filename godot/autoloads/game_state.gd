extends Node
## Autoload GameState — mode, map, team, settings, progression.

signal mode_changed(mode: String)
signal map_changed(path: String)
signal returned_to_menu

const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

var current_mode: String = "menu"
var selected_map: String = "res://scenes/maps/map_dust2.tscn"
var player_team: WeaponDefinition.Team = WeaponDefinition.Team.CT
var settings: Dictionary = {
	"sensitivity": 0.002,
	"fov": 90.0,
	"viewmodel_scale": 1.0,
	"weapon_bob": 1.0,
	"recoil_cam": 1.0,
	"sniper_sensitivity": 0.75,
	"quality": "high",
	"muzzle_flash": true,
	"volume_master": 1.0,
	"volume_sfx": 1.0,
	"volume_music": 0.7,
	"vsync": true,
	"skins": {},
}
var mmr: float = 1000.0
var xp: int = 0


func load_map(path: String) -> void:
	selected_map = path
	map_changed.emit(path)
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_warning("GameState: failed to load map %s (%s)" % [path, err])


func return_to_menu() -> void:
	current_mode = "menu"
	mode_changed.emit(current_mode)
	returned_to_menu.emit()
	get_tree().change_scene_to_file(MENU_SCENE)


func set_mode(mode: String) -> void:
	current_mode = mode
	mode_changed.emit(mode)


func add_xp(amount: int) -> void:
	xp = maxi(0, xp + amount)
