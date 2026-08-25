extends SceneTree
## Boot match map headless for a few frames.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/maps/map_dust2.tscn") as PackedScene
	if packed == null:
		printerr("FAIL map load")
		quit(1)
		return
	var level: Node = packed.instantiate()
	root.add_child(level)
	for i in 30:
		await process_frame
	var player := level.get_node_or_null("Player")
	var rm := level.get_node_or_null("RoundManager")
	if player == null:
		printerr("FAIL no player")
		quit(1)
		return
	if rm == null:
		printerr("FAIL no round manager")
		quit(1)
		return
	var bots: Array = get_nodes_in_group("bots")
	print("OK match boot player=%s bots=%d round=%s" % [player.name, bots.size(), str(rm.get("state"))])
	var catalog: Dictionary = WeaponCatalog.all()
	print("OK weapons still ", catalog.size())
	print("VERIFY_MATCH_BOOT_OK")
	quit(0)
