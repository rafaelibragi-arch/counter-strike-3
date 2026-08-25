class_name LadderVolume
extends Area3D
## Simple ladder: while overlapping, player can move up/down with wish Y from W/S.

@export var climb_speed: float = 3.5


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	if get_child_count() == 0:
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.2, 3.0, 0.6)
		cs.shape = box
		cs.position.y = 1.5
		add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _on_enter(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.set_meta("on_ladder", true)
		body.set_meta("ladder_speed", climb_speed)


func _on_exit(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.set_meta("on_ladder", false)
