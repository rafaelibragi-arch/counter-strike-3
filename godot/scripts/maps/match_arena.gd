class_name MatchArena
extends Node3D
## Builds a playable CS-like match: player, bots, round, bomb sites, buy, HUD.

@export var map_id: StringName = &"dust2"
@export var bot_count: int = 5
@export var mode: String = "casual"

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const LadderVol := preload("res://scripts/maps/ladder_volume.gd")

var player: CharacterBody3D
var round_mgr: RoundManager
var hud_layer: CanvasLayer
var hud_label: Label
var buy_open: bool = false
var in_buy_zone: bool = true
var has_bomb: bool = false
var bomb_planted_pos: Vector3 = Vector3.ZERO
var _plant_held: float = 0.0
var _defuse_held: float = 0.0


func _ready() -> void:
	_build_world_if_needed()
	_spawn_player()
	_spawn_bots()
	_setup_round()
	_setup_hud()
	_setup_sites()
	if has_node("/root/AudioBus"):
		AudioBus.play_sfx(&"round_start")
	if mode == "deathmatch":
		# free for all feel — skip freeze length by jumping to live quickly
		pass


func _process(delta: float) -> void:
	_update_bomb_actions(delta)
	_update_hud()
	if Input.is_action_just_pressed("ui_cancel"):
		if buy_open:
			buy_open = false
		elif has_node("/root/GameState"):
			GameState.return_to_menu()
	if Input.is_action_just_pressed("buy_menu"):
		_toggle_buy()
	_handle_buy_keys()


func _build_world_if_needed() -> void:
	if has_node("Floor"):
		return
	# Procedural graybox if scene is empty stub
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(48, 0.4, 48)
	cs.shape = box
	cs.position.y = -0.2
	floor_body.add_child(cs)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = box.size
	mesh.mesh = bm
	mesh.position.y = -0.2
	floor_body.add_child(mesh)
	add_child(floor_body)

	var light := DirectionalLight3D.new()
	light.light_energy = 1.2
	light.shadow_enabled = true
	light.rotation_degrees = Vector3(-45, 30, 0)
	add_child(light)

	# Cover crates — layout varies by map_id
	match String(map_id):
		"mirage":
			for i in 8:
				_add_box(Vector3(-10 + i * 2.5, 0.6, -4), Vector3(1.0, 1.2, 1.0), Color(0.45, 0.42, 0.38))
			_add_box(Vector3(2, 2.0, 2), Vector3(10, 4, 0.6), Color(0.5, 0.48, 0.4))
		"inferno":
			for i in 5:
				_add_box(Vector3(-6 + i * 3.0, 0.75, 5), Vector3(1.4, 1.5, 1.4), Color(0.55, 0.35, 0.25))
			_add_box(Vector3(-2, 1.2, -2), Vector3(12, 2.4, 0.5), Color(0.4, 0.32, 0.28))
		_:
			for i in 6:
				_add_box(Vector3(-8 + i * 3.0, 0.5, -6), Vector3(1.2, 1.0, 1.2), Color(0.55, 0.4, 0.25))
			_add_box(Vector3(0, 1.5, 0), Vector3(8, 3, 0.5), Color(0.35, 0.38, 0.42))
	# Ramp wedge
	var ramp := StaticBody3D.new()
	ramp.collision_layer = 1
	ramp.transform = Transform3D(Basis.from_euler(Vector3(0, 0, deg_to_rad(-15))), Vector3(-12, 0.8, 4))
	var rcs := CollisionShape3D.new()
	var rbox := BoxShape3D.new()
	rbox.size = Vector3(8, 1.5, 3)
	rcs.shape = rbox
	ramp.add_child(rcs)
	add_child(ramp)
	# Ladder
	var ladder: Area3D = LadderVol.new() as Area3D
	ladder.position = Vector3(6, 0, -8)
	add_child(ladder)
	_add_box(Vector3(6, 1.5, -9.2), Vector3(2, 3, 0.4), Color(0.3, 0.3, 0.35))

	_build_navmesh()


func _build_navmesh() -> void:
	var region := NavigationRegion3D.new()
	region.name = "NavRegion"
	var mesh := NavigationMesh.new()
	mesh.cell_size = 0.25
	mesh.agent_radius = 0.4
	mesh.agent_height = 1.8
	# Flat walkable plane matching floor
	mesh.vertices = PackedVector3Array([
		Vector3(-24, 0, -24), Vector3(24, 0, -24), Vector3(24, 0, 24), Vector3(-24, 0, 24),
	])
	mesh.polygons = [PackedInt32Array([0, 1, 2, 3])]
	region.navigation_mesh = mesh
	add_child(region)


func _add_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = pos
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	body.add_child(mi)
	add_child(body)


func _spawn_player() -> void:
	# Remove stub camera if any
	var stub_cam := get_node_or_null("Camera3D")
	if stub_cam:
		stub_cam.queue_free()
	player = PLAYER_SCENE.instantiate() as CharacterBody3D
	player.name = "Player"
	add_child(player)
	player.global_position = Vector3(-10, 0.05, 10)
	var combat := player.get_node_or_null("Combatant") as Combatant
	if combat:
		combat.team = WeaponDefinition.Team.CT
		combat.give_weapon(&"usps")
		combat.give_weapon(&"m4")
		combat.give_weapon(&"knife")
		combat.armor = 100.0
		combat.has_helmet = true
		combat.money = 800
	var wc := player.get_node_or_null("WeaponController") as WeaponController
	if wc:
		wc.select_slot(WeaponDefinition.Slot.PRIMARY)
	has_bomb = false
	# T side gets bomb on casual — give bomb carrier to a bot; player CT


func _spawn_bots() -> void:
	for i in bot_count:
		var bot := BotController.new()
		bot.name = "Bot_%d" % i
		bot.team = WeaponDefinition.Team.T if i < bot_count else WeaponDefinition.Team.CT
		bot.weapon_id = &"ak" if bot.team == WeaponDefinition.Team.T else &"m4"
		bot.difficulty = BotController.Difficulty.NORMAL
		bot.target_path = NodePath("../Player")
		# Capsule
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.4
		cap.height = 1.8
		cs.shape = cap
		cs.position.y = 0.9
		bot.add_child(cs)
		var mesh := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.35
		cm.height = 1.6
		mesh.mesh = cm
		mesh.position.y = 0.9
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.8, 0.35, 0.2) if bot.team == WeaponDefinition.Team.T else Color(0.25, 0.45, 0.85)
		mesh.material_override = mat
		bot.add_child(mesh)
		# Head hitbox for headshots
		var head := Area3D.new()
		head.name = "Head"
		head.collision_layer = 4
		head.position.y = 1.62
		var hcs := CollisionShape3D.new()
		var sph := SphereShape3D.new()
		sph.radius = 0.18
		hcs.shape = sph
		head.add_child(hcs)
		bot.add_child(head)
		var agent := NavigationAgent3D.new()
		agent.path_desired_distance = 0.75
		agent.target_desired_distance = 1.25
		bot.add_child(agent)
		bot.nav_agent = agent
		bot.add_to_group("bots")
		bot.add_to_group("combatant")
		add_child(bot)
		bot.global_position = Vector3(8 + (i % 3) * 2.0, 0.05, -8 - (i / 3) * 2.0)
		bot.collision_layer = 2
		bot.collision_mask = 1
		if i == 0:
			bot.set_meta("has_bomb", true)


func _setup_round() -> void:
	round_mgr = RoundManager.new()
	round_mgr.name = "RoundManager"
	add_child(round_mgr)
	round_mgr.start_match()
	round_mgr.round_ended.connect(_on_round_ended)
	round_mgr.bomb_planted.connect(func():
		if has_node("/root/AudioBus"):
			AudioBus.play_sfx(&"bomb")
	)


func _setup_hud() -> void:
	hud_layer = CanvasLayer.new()
	hud_layer.name = "MatchHUD"
	hud_label = Label.new()
	hud_label.position = Vector2(16, 16)
	hud_label.size = Vector2(700, 280)
	var ls := LabelSettings.new()
	ls.font_size = 16
	ls.outline_size = 4
	ls.outline_color = Color(0, 0, 0, 0.85)
	hud_label.label_settings = ls
	hud_layer.add_child(hud_label)
	add_child(hud_layer)
	# Hide player debug or leave both
	var dbg := player.get_node_or_null("HUD/DebugLabel") as Label
	if dbg:
		dbg.visible = false


func _setup_sites() -> void:
	_add_site("BombsiteA", Vector3(10, 0.1, 8), Vector3(6, 2, 6))
	_add_site("BombsiteB", Vector3(-14, 0.1, -10), Vector3(6, 2, 6))
	_add_buy_zone(Vector3(-10, 0.1, 10), Vector3(8, 2, 8))


func _add_site(site_name: String, pos: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.name = site_name
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	area.add_child(cs)
	var marker := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(size.x, 0.05, size.z)
	marker.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.3, 0.2, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marker.material_override = mat
	area.add_child(marker)
	add_child(area)


func _add_buy_zone(pos: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.name = "BuyZone"
	area.position = pos
	area.collision_mask = 2
	area.monitoring = true
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	area.add_child(cs)
	area.body_entered.connect(func(b):
		if b.is_in_group("player"):
			in_buy_zone = true
	)
	area.body_exited.connect(func(b):
		if b.is_in_group("player"):
			in_buy_zone = false
			buy_open = false
	)
	add_child(area)


func _toggle_buy() -> void:
	if round_mgr and round_mgr.state != RoundManager.State.FREEZE and round_mgr.state != RoundManager.State.LIVE:
		return
	# Buy only in freeze + buy zone (casual: allow freeze only for simplicity)
	if round_mgr.state != RoundManager.State.FREEZE:
		buy_open = false
		return
	if not in_buy_zone:
		return
	buy_open = not buy_open


func _handle_buy_keys() -> void:
	if not buy_open:
		return
	var combat := player.get_node_or_null("Combatant") as Combatant
	if combat == null:
		return
	# Number keys while buy open
	if Input.is_physical_key_pressed(KEY_F1):
		_try_buy(combat, &"m4")
	elif Input.is_physical_key_pressed(KEY_F2):
		_try_buy(combat, &"ak")
	elif Input.is_physical_key_pressed(KEY_F3):
		_try_buy(combat, &"awp")
	elif Input.is_physical_key_pressed(KEY_F4):
		_try_buy(combat, &"deagle")
	elif Input.is_physical_key_pressed(KEY_F5):
		combat.buy_armor(true)
	elif Input.is_physical_key_pressed(KEY_F6):
		_try_buy(combat, &"m4a1s")
	elif Input.is_physical_key_pressed(KEY_F7):
		_try_buy(combat, &"zeus")


func _try_buy(combat: Combatant, wid: StringName) -> void:
	var def := WeaponCatalog.get_weapon(wid)
	if def == null:
		return
	if combat.try_spend(def.price):
		combat.give_weapon(wid)
		var wc := player.get_node_or_null("WeaponController") as WeaponController
		if wc:
			wc.select_slot(def.slot)
		if has_node("/root/AudioBus"):
			AudioBus.play_sfx(&"ui")


func _update_bomb_actions(delta: float) -> void:
	if round_mgr == null or player == null:
		return
	var e_held := Input.is_physical_key_pressed(KEY_E)
	# Plant: T with bomb on site (player is CT in default — allow training plant with V)
	if Input.is_physical_key_pressed(KEY_V) and round_mgr.state == RoundManager.State.LIVE:
			if _player_on_site():
				if round_mgr.tick_plant(delta):
					bomb_planted_pos = player.global_position
					has_bomb = false
					_plant_held = 0.0
			else:
				round_mgr.cancel_plant()
				_plant_held = 0.0
	else:
		if round_mgr:
			round_mgr.cancel_plant()
		_plant_held = 0.0

	# Defuse: E on planted bomb
	if e_held and round_mgr.state == RoundManager.State.BOMB_PLANTED:
		if player.global_position.distance_to(bomb_planted_pos) < 2.0:
			var combat := player.get_node_or_null("Combatant") as Combatant
			var kit: bool = false
			if combat != null:
				kit = bool(combat.get_meta("has_kit", false))
			round_mgr.begin_defuse(kit)
		else:
			round_mgr.stop_defuse()
	else:
		if round_mgr.defusing:
			round_mgr.stop_defuse()


func _player_on_site() -> bool:
	for site_name in ["BombsiteA", "BombsiteB"]:
		var area := get_node_or_null(site_name) as Area3D
		if area and area.overlaps_body(player):
			return true
	return false


func _on_round_ended(winner: StringName) -> void:
	if has_node("/root/AudioBus"):
		AudioBus.play_sfx(&"ui")
	var combat := player.get_node_or_null("Combatant") as Combatant if player else null
	if combat and round_mgr:
		var ct_won := winner == &"CT"
		var player_won := (combat.team == WeaponDefinition.Team.CT and ct_won) or (combat.team == WeaponDefinition.Team.T and not ct_won)
		var streak := round_mgr.loss_streak_ct if combat.team == WeaponDefinition.Team.CT else round_mgr.loss_streak_t
		Economy.apply_round_end(combat, player_won, streak)
		if has_node("/root/Matchmaking") and GameState.current_mode == "ranked":
			Matchmaking.mmr += 16.0 if player_won else -16.0
			GameState.mmr = Matchmaking.mmr
	# Respawn after short delay; RoundManager advances FREEZE on its own
	await get_tree().create_timer(3.0).timeout
	_respawn_all()


func _respawn_all() -> void:
	if player:
		player.global_position = Vector3(-10, 0.05, 10)
		var c := player.get_node_or_null("Combatant") as Combatant
		if c:
			c.heal_full()
	for b in get_tree().get_nodes_in_group("bots"):
		if b is BotController:
			(b as BotController).global_position.y = 0.05
			var bc := (b as BotController).combatant
			if bc:
				bc.heal_full()


func _update_hud() -> void:
	if hud_label == null or player == null:
		return
	var c := player.get_node_or_null("Combatant") as Combatant
	var wc := player.get_node_or_null("WeaponController") as WeaponController
	var wname := "-"
	var ammo := "-"
	if wc and wc.current_weapon():
		wname = wc.current_weapon().display_name
		ammo = "%d / %d" % [wc.mag, wc.reserve_ammo]
	var st := "?"
	var tleft := 0.0
	var score := "0:0"
	if round_mgr:
		st = RoundManager.State.keys()[round_mgr.state]
		tleft = round_mgr.bomb_time_left if round_mgr.state == RoundManager.State.BOMB_PLANTED else round_mgr.time_left
		score = "%d : %d" % [round_mgr.score_ct, round_mgr.score_t]
	var buy_line := ""
	if buy_open:
		buy_line = "\nBUY: F1 M4 | F2 AK | F3 AWP | F4 Deagle | F5 Armor | F6 M4A1-S | F7 Zeus | B close"
	elif round_mgr and round_mgr.state == RoundManager.State.FREEZE and in_buy_zone:
		buy_line = "\n[B] Buy menu"
	hud_label.text = (
		"Clashpoint  %s  |  %s\n" % [map_id, mode]
		+ "Score CT:T  %s    Round %s    Time %.0f\n" % [score, st, tleft]
		+ "HP %d  Armor %d  $%d\n" % [int(c.hp) if c else 0, int(c.armor) if c else 0, c.money if c else 0]
		+ "%s   ammo %s\n" % [wname, ammo]
		+ "LMB shoot | R reload | 1/2/3 weapons | V plant | E defuse | Esc menu"
		+ buy_line
	)
