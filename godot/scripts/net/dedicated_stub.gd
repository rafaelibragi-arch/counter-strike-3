extends SceneTree
## Headless dedicated stub — hosts ENet via NetSession autoload.


func _init() -> void:
	call_deferred("_boot")


func _boot() -> void:
	var port := 7777
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		port = int(args[0])
	print("Clashpoint dedicated stub starting on ", port)
	var ns := root.get_node_or_null("NetSession")
	if ns == null:
		printerr("FAIL NetSession missing")
		quit(1)
		return
	var err: Error = ns.host_lan(port)
	print("host_lan → ", err, " mode=", ns.mode)
	await create_timer(0.5).timeout
	print("DEDICATED_STUB_OK")
	quit(0)
