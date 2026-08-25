extends Node3D
## Graybox helpers. Colliders use explicit BoxShape sizes in the scene
## (no scale on CollisionShape3D — Jolt-safe).

@onready var player: CharacterBody3D = $Player


func _ready() -> void:
	print("[Clashpoint] Test level ready — 64 Hz, Jolt, Source pmove")
	print("[Clashpoint] Expected jump apex ≈ %.2f m" % _expected_apex())


func _expected_apex() -> float:
	var cfg := load("res://resources/cs2_clashpoint_move.tres") as MoveConfig
	if cfg == null:
		return 1.37
	return (cfg.jump_vel * cfg.jump_vel) / (2.0 * cfg.gravity)
