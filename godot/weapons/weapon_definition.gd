class_name WeaponDefinition
extends Resource
## Clashpoint weapon stats resource (Year-1).

enum Slot { PRIMARY, SECONDARY, MELEE, GRENADE }
enum Team { T, CT, BOTH }
enum Type { RIFLE, SMG, SHOTGUN, SNIPER, PISTOL, MELEE, GRENADE }

@export var id: StringName = &""
@export var display_name: String = ""
@export var slot: Slot = Slot.PRIMARY
@export var team: Team = Team.BOTH
@export var type: Type = Type.RIFLE
@export var price: int = 0
@export var damage: float = 0.0
@export_range(0.0, 1.0) var armor_pen: float = 0.77
@export var fire_interval_ms: int = 100
@export var mag_size: int = 30
@export var reserve: int = 90
@export var reload_time: float = 2.5
@export var recoil: float = 1.0
@export var spread: float = 0.02
@export var automatic: bool = true
@export var pellets: int = 1
@export var range_melee: float = 0.0
@export var kill_award: int = 300
@export var head_mul: float = 4.0
@export var chest_mul: float = 1.0
@export var stomach_mul: float = 1.15
@export var legs_mul: float = 0.75


func hitgroup_mul(hitgroup: StringName) -> float:
	match hitgroup:
		&"head":
			return head_mul
		&"chest":
			return chest_mul
		&"stomach":
			return stomach_mul
		&"legs", &"leg":
			return legs_mul
		_:
			return chest_mul


static func make(
	p_id: StringName,
	p_name: String,
	p_slot: Slot,
	p_team: Team,
	p_type: Type,
	p_price: int,
	p_damage: float,
	p_armor_pen: float,
	p_fire_ms: int,
	p_mag: int,
	p_reserve: int,
	p_reload: float,
	p_recoil: float,
	p_spread: float,
	p_auto: bool,
	p_pellets: int = 1,
	p_melee_range: float = 0.0,
	p_kill_award: int = 300,
) -> WeaponDefinition:
	var w := WeaponDefinition.new()
	w.id = p_id
	w.display_name = p_name
	w.slot = p_slot
	w.team = p_team
	w.type = p_type
	w.price = p_price
	w.damage = p_damage
	w.armor_pen = p_armor_pen
	w.fire_interval_ms = p_fire_ms
	w.mag_size = p_mag
	w.reserve = p_reserve
	w.reload_time = p_reload
	w.recoil = p_recoil
	w.spread = p_spread
	w.automatic = p_auto
	w.pellets = p_pellets
	w.range_melee = p_melee_range
	w.kill_award = p_kill_award
	return w
