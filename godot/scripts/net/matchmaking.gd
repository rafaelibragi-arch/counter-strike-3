extends Node
## Autoload Matchmaking — fake queue that finds an offline bot match.

signal queue_started(mode: StringName)
signal queue_cancelled
signal match_found(map_path: String, mode: StringName)

var mmr: float = 1000.0
var party_size: int = 1
var in_queue: bool = false
var queue_mode: StringName = &""

var _timer: SceneTreeTimer


func queue_casual(party: int = 1) -> void:
	_start_queue(&"casual", party)


func queue_ranked(party: int = 1) -> void:
	_start_queue(&"ranked", party)


func cancel_queue() -> void:
	in_queue = false
	queue_mode = &""
	_timer = null
	queue_cancelled.emit()


func _start_queue(mode: StringName, party: int) -> void:
	party_size = clampi(party, 1, 5)
	queue_mode = mode
	in_queue = true
	queue_started.emit(mode)
	_timer = get_tree().create_timer(2.0)
	_timer.timeout.connect(_on_fake_found, CONNECT_ONE_SHOT)


func _on_fake_found() -> void:
	if not in_queue:
		return
	in_queue = false
	var map_path := "res://scenes/maps/map_dust2.tscn"
	match_found.emit(map_path, queue_mode)
	if has_node("/root/GameState"):
		GameState.current_mode = String(queue_mode)
		GameState.load_map(map_path)
