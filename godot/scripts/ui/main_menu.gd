extends Control
## Clashpoint main menu.

@onready var status_label: Label = $Center/VBox/StatusLabel


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if has_node("/root/Matchmaking"):
		Matchmaking.match_found.connect(_on_match_found)


func _on_training_pressed() -> void:
	_play("training", "res://scenes/maps/map_training.tscn")


func _on_casual_pressed() -> void:
	_play("casual", "res://scenes/maps/map_dust2.tscn")


func _on_dm_pressed() -> void:
	_play("deathmatch", "res://scenes/maps/map_mirage.tscn")


func _on_ranked_pressed() -> void:
	if status_label:
		status_label.text = "Ranked: queuing… (MMR %d)" % int(Matchmaking.mmr if has_node("/root/Matchmaking") else 1000)
	if has_node("/root/Matchmaking"):
		Matchmaking.queue_ranked()
	else:
		if status_label:
			status_label.text = "Ranked stub — Matchmaking missing"


func _on_lan_pressed() -> void:
	if has_node("/root/NetSession"):
		var err := NetSession.host_lan(7777)
		if status_label:
			if err == OK:
				status_label.text = "LAN host on :7777 — loading Dust2…"
			else:
				status_label.text = "LAN host failed (%s) — offline Dust2" % err
	_play("lan", "res://scenes/maps/map_dust2.tscn")


func _on_settings_pressed() -> void:
	if status_label:
		status_label.text = "Settings in GameState.settings (sens/FOV). Maps: Dust2 / Mirage / Inferno."


func _on_quit_pressed() -> void:
	get_tree().quit()


func _play(mode: String, map_path: String) -> void:
	if has_node("/root/AudioBus"):
		AudioBus.play_sfx(&"ui")
	if has_node("/root/NetSession"):
		NetSession.disconnect_session()
	if has_node("/root/GameState"):
		GameState.set_mode(mode)
		GameState.player_team = WeaponDefinition.Team.CT
		GameState.load_map(map_path)
	else:
		get_tree().change_scene_to_file(map_path)


func _on_match_found(map_path: String, mode: StringName) -> void:
	if status_label:
		status_label.text = "Match found: %s" % mode
	if has_node("/root/GameState"):
		GameState.set_mode(String(mode))
		GameState.mmr = Matchmaking.mmr
		GameState.load_map(map_path)
