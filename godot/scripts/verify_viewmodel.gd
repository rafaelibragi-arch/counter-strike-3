extends SceneTree
## FP viewmodel verification — headless smoke.

const TEST_LEVEL := "res://scenes/test_level.tscn"
const _PreloadVm := preload("res://scripts/fp/viewmodel_controller.gd")
const _PreloadVw := preload("res://scripts/fp/viewmodel_weapon.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var failed := 0
	var packed: PackedScene = load(TEST_LEVEL)
	if packed == null:
		printerr("FAIL: could not load test_level")
		quit(1)
		return

	var level: Node = packed.instantiate()
	root.add_child(level)
	for i in 15:
		await process_frame

	var player := level.get_node_or_null("Player") as CharacterBody3D
	if player == null:
		printerr("FAIL: Player missing")
		quit(1)
		return

	_setup_player_loadout(player)
	for i in 5:
		await process_frame

	var vm: Node3D = player.get_node_or_null("Head/Camera3D/ViewModel")
	if vm == null:
		failed += _fail("ViewModel node missing on Player")
	else:
		failed += _test_viewmodel_present(vm)
		failed += await _test_weapon_swap(vm, player)
		failed += await _test_ads(vm, player)
		failed += _test_dump(vm)

	if failed == 0:
		print("VERIFY_VIEWMODEL_OK")
		quit(0)
	else:
		print("VERIFY_VIEWMODEL_FAIL %d" % failed)
		quit(1)


func _test_viewmodel_present(vm: Node3D) -> int:
	if vm.get_child_count() < 1:
		return _fail("ViewModel has no children")
	var wpn: Node3D = vm.get_node_or_null("WeaponView")
	if wpn == null or not wpn.has_method("get_weapon_root"):
		return _fail("WeaponView missing")
	if wpn.get_weapon_root() == null:
		return _fail("weapon root mesh missing")
	return _ok("viewmodel mesh present weapon=%s" % String(wpn.weapon_id))


func _test_weapon_swap(vm: Node3D, player: CharacterBody3D) -> int:
	var wc := player.get_node_or_null("WeaponController") as WeaponController
	if wc == null:
		return _fail("WeaponController missing")
	wc.select_slot(WeaponDefinition.Slot.SECONDARY)
	for i in 30:
		await process_frame
	var wpn: Node3D = vm.get_node_or_null("WeaponView")
	if wpn == null:
		return _fail("WeaponView missing after swap")
	var cw := wc.current_weapon()
	if cw == null:
		return _fail("no current weapon after secondary select")
	if wpn.weapon_id != cw.id:
		return _fail("viewmodel weapon mismatch: vm=%s wc=%s" % [String(wpn.weapon_id), String(cw.id)])
	return _ok("weapon swap secondary=%s" % String(cw.id))


func _test_ads(vm: Node3D, player: CharacterBody3D) -> int:
	var cam := player.get_node_or_null("Head/Camera3D") as Camera3D
	if cam == null:
		return _fail("camera missing")
	var fov0 := cam.fov
	vm.set_ads(true)
	for i in 8:
		await process_frame
	if not vm.ads:
		return _fail("ads flag not set")
	var scope := player.get_node_or_null("HUD/ScopeOverlay") as Control
	wc_select_awp(player)
	for i in 10:
		await process_frame
	vm.set_ads(true)
	for i in 10:
		await process_frame
	if scope and scope.visible:
		return _ok("ADS scope overlay visible for AWP")
	vm.set_ads(false)
	for i in 5:
		await process_frame
	return _ok("ADS fov lerp started fov0=%.1f fov=%.1f" % [fov0, cam.fov])


func wc_select_awp(player: CharacterBody3D) -> void:
	var combat := player.get_node_or_null("Combatant") as Combatant
	var wc := player.get_node_or_null("WeaponController") as WeaponController
	if combat and wc:
		combat.give_weapon(&"awp")
		wc.select_slot(WeaponDefinition.Slot.PRIMARY)


func _setup_player_loadout(player: CharacterBody3D) -> void:
	var combat := player.get_node_or_null("Combatant") as Combatant
	var wc := player.get_node_or_null("WeaponController") as WeaponController
	if combat == null or wc == null:
		return
	combat.give_weapon(&"ak")
	combat.give_weapon(&"usps")
	combat.give_weapon(&"awp")
	wc.select_slot(WeaponDefinition.Slot.PRIMARY)


func _test_dump(vm: Node3D) -> int:
	if not vm.has_method("dump_state"):
		return _fail("dump_state missing on ViewModel")
	var d: Dictionary = vm.dump_state()
	if not d.has("weapon"):
		return _fail("dump_state missing weapon key")
	return _ok("dump_state weapon=%s ads=%s" % [d.get("weapon"), d.get("ads")])


func _ok(msg: String) -> int:
	print("OK: ", msg)
	return 0


func _fail(msg: String) -> int:
	print("FAIL: ", msg)
	return 1
