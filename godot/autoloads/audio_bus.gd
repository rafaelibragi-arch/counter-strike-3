extends Node
## Autoload AudioBus — Master/SFX/Music + procedural beep SFX.

const BUS_MASTER := "Master"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"

var _player: AudioStreamPlayer
var _gen: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _beep_samples_left: int = 0
var _beep_phase: float = 0.0
var _beep_freq: float = 440.0


func _ready() -> void:
	_ensure_buses()
	_player = AudioStreamPlayer.new()
	_player.bus = BUS_SFX
	_gen = AudioStreamGenerator.new()
	_gen.mix_rate = 22050.0
	_gen.buffer_length = 0.1
	_player.stream = _gen
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(_delta: float) -> void:
	if _playback == null or _beep_samples_left <= 0:
		return
	var to_fill := mini(_playback.get_frames_available(), _beep_samples_left)
	for _i in to_fill:
		var s := sin(_beep_phase) * 0.25
		_playback.push_frame(Vector2(s, s))
		_beep_phase += TAU * _beep_freq / _gen.mix_rate
		_beep_samples_left -= 1


func play_sfx(sfx_name: StringName) -> void:
	print("[AudioBus] sfx:", sfx_name)
	match String(sfx_name):
		"shot", "fire", "shoot":
			_beep(880.0, 0.04)
		"reload":
			_beep(220.0, 0.08)
		"hit":
			_beep(1200.0, 0.03)
		"ui":
			_beep(660.0, 0.05)
		"bomb":
			_beep(160.0, 0.2)
		_:
			_beep(440.0, 0.05)


func set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))


func _beep(freq: float, duration: float) -> void:
	_beep_freq = freq
	_beep_phase = 0.0
	_beep_samples_left = int(duration * _gen.mix_rate)
	if _playback == null and _player:
		_playback = _player.get_stream_playback() as AudioStreamGeneratorPlayback


func _ensure_buses() -> void:
	if AudioServer.get_bus_index(BUS_SFX) < 0:
		AudioServer.add_bus()
		var idx := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS_SFX)
		AudioServer.set_bus_send(idx, BUS_MASTER)
	if AudioServer.get_bus_index(BUS_MUSIC) < 0:
		AudioServer.add_bus()
		var idx2 := AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx2, BUS_MUSIC)
		AudioServer.set_bus_send(idx2, BUS_MASTER)
