extends SceneTree
## Headless smoke check for Year-1 scripts.

const SprayPatternsLib := preload("res://weapons/spray_patterns.gd")

func _init() -> void:
	var failed := 0
	failed += _check_weapons()
	failed += _check_combatant()
	failed += _check_economy()
	failed += _check_round()
	failed += _check_grenade()
	quit(1 if failed > 0 else 0)


func _check_weapons() -> int:
	var all := WeaponCatalog.all()
	var need := [&"ak", &"galil", &"m4", &"m4a1s", &"awp", &"mac10", &"mp9", &"ump", &"nova", &"xm", &"mag7", &"glock", &"usps", &"deagle", &"knife", &"p250", &"mp7", &"zeus"]
	for id in need:
		var w: WeaponDefinition = all.get(id)
		if w == null:
			push_error("missing weapon %s" % id)
			return 1
	var ak: WeaponDefinition = all[&"ak"]
	if ak.damage != 36.0 or ak.fire_interval_ms != 100 or ak.price != 2700:
		push_error("ak stats mismatch")
		return 1
	if ak.armor_pen != 0.77 or ak.kill_award != 300:
		push_error("ak ap/ka mismatch")
		return 1
	var awp: WeaponDefinition = all[&"awp"]
	if awp.automatic or awp.armor_pen != 0.97 or awp.kill_award != 100:
		push_error("awp mismatch")
		return 1
	var nova: WeaponDefinition = all[&"nova"]
	if nova.pellets != 9:
		push_error("nova pellets")
		return 1
	var spray_ak: Array = SprayPatternsLib.for_weapon(&"ak")
	if spray_ak.size() < 20:
		push_error("ak spray pattern missing")
		return 1
	print("OK weapons count=", all.size(), " ak_spray=", spray_ak.size())
	return 0


func _check_combatant() -> int:
	var c := Combatant.new()
	c.heal_full()
	c.armor = 100.0
	c.has_helmet = true
	var dmg := c.apply_damage(36.0, &"chest", 0.77, null)
	if dmg <= 0.0 or c.hp >= 100.0:
		push_error("damage failed")
		return 1
	c.give_weapon(&"ak")
	if c.get_weapon(WeaponDefinition.Slot.PRIMARY) == null:
		push_error("give_weapon failed")
		return 1
	print("OK combatant hp=", c.hp, " armor=", c.armor)
	return 0


func _check_economy() -> int:
	if Economy.loss_bonus(0) != 1400:
		push_error("loss bonus 0")
		return 1
	if Economy.loss_bonus(99) != 3400:
		push_error("loss bonus cap")
		return 1
	if Economy.STARTING_MONEY != 800 or Economy.MAX_MONEY != 16000:
		push_error("money constants")
		return 1
	print("OK economy")
	return 0


func _check_round() -> int:
	var rm := RoundManager.new()
	rm.start_match()
	if rm.state != RoundManager.State.FREEZE:
		push_error("expected FREEZE")
		return 1
	rm.time_left = 0.0
	rm._process(0.016)
	if rm.state != RoundManager.State.LIVE:
		push_error("expected LIVE")
		return 1
	rm.plant_bomb()
	if rm.state != RoundManager.State.BOMB_PLANTED:
		push_error("expected BOMB_PLANTED")
		return 1
	print("OK round_manager")
	return 0


func _check_grenade() -> int:
	var g := Grenade.new()
	g.kind = Grenade.Kind.HE
	g.fuse = 0.01
	print("OK grenade kind=", g.kind)
	g.free()
	return 0
