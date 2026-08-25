class_name HUD
extends CanvasLayer
## In-match HUD: hp, armor, ammo, money, timer, score, bomb, killfeed.

@export var combatant_path: NodePath
@export var weapon_controller_path: NodePath
@export var round_manager_path: NodePath

var combatant: Combatant
var weapons: WeaponController
var rounds: RoundManager

var hp_label: Label
var armor_label: Label
var ammo_label: Label
var money_label: Label
var timer_label: Label
var score_label: Label
var bomb_label: Label
var killfeed_label: Label

var _killfeed_clear_at: float = 0.0


func _ready() -> void:
	_build_ui()
	combatant = get_node_or_null(combatant_path) as Combatant
	weapons = get_node_or_null(weapon_controller_path) as WeaponController
	rounds = get_node_or_null(round_manager_path) as RoundManager
	if combatant == null:
		combatant = get_parent().get_node_or_null("Combatant") as Combatant
	if weapons == null:
		weapons = get_parent().get_node_or_null("WeaponController") as WeaponController
	if rounds == null and has_node("/root/RoundManager"):
		rounds = get_node("/root/RoundManager") as RoundManager
	if weapons:
		weapons.hit_confirmed.connect(_on_hit)
		weapons.shot_fired.connect(_on_shot)


func _process(_delta: float) -> void:
	_refresh()
	if _killfeed_clear_at > 0.0 and Time.get_ticks_msec() / 1000.0 > _killfeed_clear_at:
		killfeed_label.text = ""
		_killfeed_clear_at = 0.0


func _refresh() -> void:
	if combatant:
		hp_label.text = "HP %d" % int(combatant.hp)
		armor_label.text = "ARM %d%s" % [int(combatant.armor), " H" if combatant.has_helmet else ""]
		money_label.text = "$%d" % combatant.money
	if weapons:
		var w := weapons.current_weapon()
		if w and w.type == WeaponDefinition.Type.MELEE:
			ammo_label.text = "— / —"
		else:
			ammo_label.text = "%d / %d" % [weapons.mag, weapons.reserve_ammo]
	if rounds:
		var t := rounds.bomb_time_left if rounds.state == RoundManager.State.BOMB_PLANTED else rounds.time_left
		timer_label.text = _fmt_time(t)
		score_label.text = "CT %d  :  %d T" % [rounds.score_ct, rounds.score_t]
		bomb_label.text = _bomb_text()
	else:
		timer_label.text = "--:--"
		score_label.text = "CT 0  :  0 T"
		bomb_label.text = ""


func _bomb_text() -> String:
	if rounds == null:
		return ""
	match rounds.state:
		RoundManager.State.FREEZE:
			return "FREEZE"
		RoundManager.State.LIVE:
			return ""
		RoundManager.State.BOMB_PLANTED:
			if rounds.defusing:
				return "DEFUSING…"
			return "BOMB PLANTED"
		RoundManager.State.ROUND_END:
			return "ROUND OVER"
		RoundManager.State.MATCH_END:
			return "MATCH OVER"
		_:
			return ""


func _on_hit(target: Combatant, damage: float, hitgroup: StringName) -> void:
	var name_str := "Bot" if target else "?"
	killfeed_label.text = "Hit %s [%s] -%d" % [name_str, hitgroup, int(damage)]
	_killfeed_clear_at = Time.get_ticks_msec() / 1000.0 + 2.5
	if has_node("/root/AudioBus"):
		AudioBus.play_sfx(&"hit")


func _on_shot(_w: WeaponDefinition) -> void:
	if has_node("/root/AudioBus"):
		AudioBus.play_sfx(&"shot")


func push_killfeed(line: String) -> void:
	killfeed_label.text = line
	_killfeed_clear_at = Time.get_ticks_msec() / 1000.0 + 3.0


func _fmt_time(seconds: float) -> String:
	var s := maxi(0, int(ceil(seconds)))
	return "%d:%02d" % [s / 60, s % 60]


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	hp_label = _mk_label(root, Vector2(24, -80), "HP 100")
	hp_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hp_label.position = Vector2(24, -80)

	armor_label = _mk_label(root, Vector2(24, -52), "ARM 0")
	armor_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	armor_label.position = Vector2(24, -52)

	money_label = _mk_label(root, Vector2(24, -24), "$800")
	money_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	money_label.position = Vector2(24, -24)

	ammo_label = _mk_label(root, Vector2(-160, -52), "30 / 90")
	ammo_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo_label.position = Vector2(-160, -52)
	ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	timer_label = _mk_label(root, Vector2(-40, 16), "1:55")
	timer_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	timer_label.position = Vector2(-100, 16)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	score_label = _mk_label(root, Vector2(0, 16), "CT 0  :  0 T")
	score_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	score_label.position = Vector2(-80, 16)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	bomb_label = _mk_label(root, Vector2(0, 48), "")
	bomb_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bomb_label.position = Vector2(-80, 48)
	bomb_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bomb_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.15))

	killfeed_label = _mk_label(root, Vector2(24, 16), "")
	killfeed_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	killfeed_label.position = Vector2(24, 16)


func _mk_label(parent: Control, _pos: Vector2, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color(0.92, 0.93, 0.95))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(l)
	return l
