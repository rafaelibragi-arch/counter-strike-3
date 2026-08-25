extends SceneTree
## Smoke: menu scene + net/matchmaking stubs.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var menu: PackedScene = load("res://scenes/ui/main_menu.tscn") as PackedScene
	if menu == null:
		printerr("FAIL menu")
		quit(1)
		return
	var n: Node = menu.instantiate()
	root.add_child(n)
	await process_frame
	await process_frame
	var ns := root.get_node_or_null("NetSession")
	var mm := root.get_node_or_null("Matchmaking")
	if ns == null:
		printerr("FAIL NetSession")
		quit(1)
		return
	if mm == null:
		printerr("FAIL Matchmaking")
		quit(1)
		return
	ns.disconnect_session()
	var err: Error = ns.host_lan(17777)
	print("OK menu + NetSession.host_lan → ", err, " mode=", ns.mode)
	mm.mmr = 1000.0
	print("OK Matchmaking mmr=", mm.mmr)
	print("VERIFY_SHIP_OK")
	quit(0)
