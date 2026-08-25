class_name Combatant
extends Node
## HP / armor / inventory attach to player or bot root.

signal died(attacker: Combatant)
signal damaged(amount: float, hitgroup: StringName, attacker: Combatant)
signal money_changed(money: int)
signal weapons_changed

@export var team: WeaponDefinition.Team = WeaponDefinition.Team.BOTH
@export var max_hp: float = 100.0
@export var starting_money: int = 800

var hp: float = 100.0
var armor: float = 0.0
var has_helmet: bool = false
var money: int = 800
var alive: bool = true
## slot -> WeaponDefinition id
var weapons: Dictionary = {}
var active_slot: WeaponDefinition.Slot = WeaponDefinition.Slot.PRIMARY


func _ready() -> void:
	heal_full()
	money = starting_money
	if not weapons.has(WeaponDefinition.Slot.MELEE):
		give_weapon(&"knife")


func apply_damage(amount: float, hitgroup: StringName, armor_pen: float, attacker: Combatant = null) -> float:
	if not alive or amount <= 0.0:
		return 0.0

	var mul := 1.0
	match hitgroup:
		&"head":
			mul = 4.0
			if has_helmet and armor > 0.0:
				mul *= 0.5
		&"stomach":
			mul = 1.15
		&"legs", &"leg":
			mul = 0.75
		_:
			mul = 1.0

	var scaled := amount * mul
	var dmg_to_hp := scaled
	if armor > 0.0:
		# CS-like: armor reduces HP damage; armor takes ~half of incoming
		dmg_to_hp = scaled * (1.0 - armor_pen * 0.5)
		armor = maxf(0.0, armor - scaled * 0.5)
		if armor <= 0.0:
			has_helmet = false

	hp = maxf(0.0, hp - dmg_to_hp)
	damaged.emit(dmg_to_hp, hitgroup, attacker)
	if hp <= 0.0:
		alive = false
		died.emit(attacker)
	return dmg_to_hp


func give_weapon(weapon_id: StringName) -> bool:
	var def := WeaponCatalog.get_weapon(weapon_id)
	if def == null:
		return false
	weapons[def.slot] = def
	weapons_changed.emit()
	return true


func get_weapon(slot: WeaponDefinition.Slot = active_slot) -> WeaponDefinition:
	return weapons.get(slot) as WeaponDefinition


func heal_full() -> void:
	hp = max_hp
	alive = true


func buy_armor(with_helmet: bool = true) -> bool:
	var cost := 1000 if with_helmet else 650
	if money < cost:
		return false
	money -= cost
	armor = 100.0
	has_helmet = with_helmet
	money_changed.emit(money)
	return true


func add_money(amount: int) -> void:
	money = clampi(money + amount, 0, Economy.MAX_MONEY)
	money_changed.emit(money)


func try_spend(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true
