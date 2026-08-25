class_name RoundManager
extends Node
## Bomb / freeze / live round flow. Autoload-friendly.

signal state_changed(state: State)
signal score_changed(ct: int, t: int)
signal bomb_planted
signal bomb_defused
signal bomb_exploded
signal round_ended(winner: StringName)

enum State { FREEZE, LIVE, BOMB_PLANTED, ROUND_END, MATCH_END }

const FREEZE_TIME := 15.0
const ROUND_TIME := 115.0
const BOMB_TIME := 40.0
const PLANT_TIME := 3.0
const DEFUSE_TIME := 10.0
const DEFUSE_TIME_KIT := 5.0
const MR12_WINS := 13

var state: State = State.FREEZE
var score_ct: int = 0
var score_t: int = 0
var round_index: int = 0
var time_left: float = FREEZE_TIME
var bomb_time_left: float = 0.0
var plant_progress: float = 0.0
var defuse_progress: float = 0.0
var defusing: bool = false
var defuser_has_kit: bool = false
var loss_streak_ct: int = 0
var loss_streak_t: int = 0
var _running: bool = false


func start_match() -> void:
	score_ct = 0
	score_t = 0
	round_index = 0
	loss_streak_ct = 0
	loss_streak_t = 0
	score_changed.emit(score_ct, score_t)
	start_round()


func start_round() -> void:
	_running = true
	round_index += 1
	plant_progress = 0.0
	defuse_progress = 0.0
	defusing = false
	bomb_time_left = 0.0
	time_left = FREEZE_TIME
	_set_state(State.FREEZE)


func _process(delta: float) -> void:
	if not _running or state == State.MATCH_END:
		return
	match state:
		State.FREEZE:
			time_left -= delta
			if time_left <= 0.0:
				time_left = ROUND_TIME
				_set_state(State.LIVE)
		State.LIVE:
			time_left -= delta
			if time_left <= 0.0:
				_end_round(&"CT") # time expired, CT win
		State.BOMB_PLANTED:
			if defusing:
				var need := DEFUSE_TIME_KIT if defuser_has_kit else DEFUSE_TIME
				defuse_progress += delta
				if defuse_progress >= need:
					_on_defused()
					return
			bomb_time_left -= delta
			if bomb_time_left <= 0.0:
				_on_exploded()
		State.ROUND_END:
			time_left -= delta
			if time_left <= 0.0:
				if score_ct >= MR12_WINS or score_t >= MR12_WINS:
					_set_state(State.MATCH_END)
					_running = false
				else:
					start_round()


func plant_bomb() -> void:
	if state != State.LIVE:
		return
	plant_progress = 0.0
	# Instant plant API; callers can drive progress externally via tick_plant
	_complete_plant()


func tick_plant(delta: float) -> bool:
	if state != State.LIVE:
		return false
	plant_progress += delta
	if plant_progress >= PLANT_TIME:
		_complete_plant()
		return true
	return false


func cancel_plant() -> void:
	plant_progress = 0.0


func begin_defuse(has_kit: bool = false) -> void:
	if state != State.BOMB_PLANTED:
		return
	defusing = true
	defuser_has_kit = has_kit
	defuse_progress = 0.0


func stop_defuse() -> void:
	defusing = false
	defuse_progress = 0.0


func on_player_death(_victim_team: WeaponDefinition.Team, alive_ct: int, alive_t: int) -> void:
	if state != State.LIVE and state != State.BOMB_PLANTED:
		return
	if alive_t <= 0 and state == State.LIVE:
		_end_round(&"CT")
	elif alive_ct <= 0:
		_end_round(&"T")


func _complete_plant() -> void:
	bomb_time_left = BOMB_TIME
	plant_progress = PLANT_TIME
	_set_state(State.BOMB_PLANTED)
	bomb_planted.emit()


func _on_defused() -> void:
	defusing = false
	bomb_defused.emit()
	_end_round(&"CT")


func _on_exploded() -> void:
	bomb_exploded.emit()
	_end_round(&"T")


func _end_round(winner: StringName) -> void:
	if state == State.ROUND_END or state == State.MATCH_END:
		return
	if winner == &"CT":
		score_ct += 1
		loss_streak_ct = 0
		loss_streak_t += 1
	else:
		score_t += 1
		loss_streak_t = 0
		loss_streak_ct += 1
	score_changed.emit(score_ct, score_t)
	time_left = 5.0
	_set_state(State.ROUND_END)
	round_ended.emit(winner)


func _set_state(s: State) -> void:
	state = s
	state_changed.emit(state)


func state_name() -> String:
	return State.keys()[state]
