class_name WeaponCatalog
extends RefCounted
## Builds WeaponDefinition dictionary in code (no per-weapon .tres).

const AP_RIFLE := 0.77
const AP_AWP := 0.97
const AP_SMG := 0.6
const AP_SHOTGUN := 0.5
const AP_KNIFE := 0.85

const KA_RIFLE := 300
const KA_AWP := 100
const KA_SMG := 600
const KA_SHOTGUN := 900
const KA_PISTOL := 300
const KA_KNIFE := 1500

static var _cache: Dictionary = {}


static func all() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	_cache = _build()
	return _cache


static func get_weapon(weapon_id: StringName) -> WeaponDefinition:
	return all().get(weapon_id) as WeaponDefinition


static func _build() -> Dictionary:
	var S := WeaponDefinition.Slot
	var T := WeaponDefinition.Team
	var Ty := WeaponDefinition.Type
	var d: Dictionary = {}

	d[&"ak"] = WeaponDefinition.make(
		&"ak", "AK-47", S.PRIMARY, T.T, Ty.RIFLE, 2700,
		36.0, AP_RIFLE, 100, 30, 90, 2.5, 1.4, 0.018, true, 1, 0.0, KA_RIFLE)
	d[&"galil"] = WeaponDefinition.make(
		&"galil", "Galil AR", S.PRIMARY, T.T, Ty.RIFLE, 1800,
		30.0, AP_RIFLE, 95, 35, 90, 2.6, 1.25, 0.02, true, 1, 0.0, KA_RIFLE)
	d[&"m4"] = WeaponDefinition.make(
		&"m4", "M4A4", S.PRIMARY, T.CT, Ty.RIFLE, 3100,
		33.0, AP_RIFLE, 90, 30, 90, 2.3, 1.05, 0.014, true, 1, 0.0, KA_RIFLE)
	d[&"m4a1s"] = WeaponDefinition.make(
		&"m4a1s", "M4A1-S", S.PRIMARY, T.CT, Ty.RIFLE, 2900,
		33.0, AP_RIFLE, 95, 25, 75, 2.4, 0.9, 0.011, true, 1, 0.0, KA_RIFLE)
	d[&"awp"] = WeaponDefinition.make(
		&"awp", "AWP", S.PRIMARY, T.BOTH, Ty.SNIPER, 4750,
		115.0, AP_AWP, 1450, 5, 30, 3.7, 2.8, 0.002, false, 1, 0.0, KA_AWP)
	d[&"mac10"] = WeaponDefinition.make(
		&"mac10", "MAC-10", S.PRIMARY, T.T, Ty.SMG, 1050,
		29.0, AP_SMG, 75, 30, 100, 2.2, 1.6, 0.028, true, 1, 0.0, KA_SMG)
	d[&"mp9"] = WeaponDefinition.make(
		&"mp9", "MP9", S.PRIMARY, T.CT, Ty.SMG, 1250,
		26.0, AP_SMG, 70, 30, 120, 2.0, 0.95, 0.02, true, 1, 0.0, KA_SMG)
	d[&"ump"] = WeaponDefinition.make(
		&"ump", "UMP-45", S.PRIMARY, T.BOTH, Ty.SMG, 1200,
		29.0, AP_SMG, 105, 25, 100, 2.4, 1.1, 0.019, true, 1, 0.0, KA_SMG)
	d[&"mp7"] = WeaponDefinition.make(
		&"mp7", "MP7", S.PRIMARY, T.BOTH, Ty.SMG, 1500,
		27.0, AP_SMG, 80, 30, 120, 2.1, 1.0, 0.018, true, 1, 0.0, KA_SMG)
	d[&"nova"] = WeaponDefinition.make(
		&"nova", "Nova", S.PRIMARY, T.BOTH, Ty.SHOTGUN, 1050,
		26.0, AP_SHOTGUN, 880, 8, 32, 3.4, 2.0, 0.06, false, 9, 0.0, KA_SHOTGUN)
	d[&"xm"] = WeaponDefinition.make(
		&"xm", "XM1014", S.PRIMARY, T.BOTH, Ty.SHOTGUN, 2000,
		20.0, AP_SHOTGUN, 280, 7, 32, 3.0, 1.7, 0.055, true, 6, 0.0, KA_SHOTGUN)
	d[&"mag7"] = WeaponDefinition.make(
		&"mag7", "MAG-7", S.PRIMARY, T.CT, Ty.SHOTGUN, 1300,
		30.0, AP_SHOTGUN, 850, 5, 32, 2.8, 2.1, 0.065, false, 8, 0.0, KA_SHOTGUN)
	d[&"glock"] = WeaponDefinition.make(
		&"glock", "Glock-18", S.SECONDARY, T.T, Ty.PISTOL, 200,
		28.0, 0.65, 170, 20, 120, 1.9, 0.7, 0.022, false, 1, 0.0, KA_PISTOL)
	d[&"usps"] = WeaponDefinition.make(
		&"usps", "USP-S", S.SECONDARY, T.CT, Ty.PISTOL, 200,
		35.0, 0.80, 220, 12, 24, 2.1, 0.85, 0.014, false, 1, 0.0, KA_PISTOL)
	d[&"p250"] = WeaponDefinition.make(
		&"p250", "P250", S.SECONDARY, T.BOTH, Ty.PISTOL, 300,
		33.0, 0.70, 180, 13, 26, 2.0, 0.9, 0.016, false, 1, 0.0, KA_PISTOL)
	d[&"deagle"] = WeaponDefinition.make(
		&"deagle", "Desert Eagle", S.SECONDARY, T.BOTH, Ty.PISTOL, 700,
		63.0, 0.85, 370, 7, 35, 2.2, 2.4, 0.01, false, 1, 0.0, KA_PISTOL)
	d[&"knife"] = WeaponDefinition.make(
		&"knife", "Knife", S.MELEE, T.BOTH, Ty.MELEE, 0,
		65.0, AP_KNIFE, 550, 0, 0, 0.0, 0.0, 0.0, false, 1, 2.4, KA_KNIFE)
	d[&"zeus"] = WeaponDefinition.make(
		&"zeus", "Zeus x27", S.SECONDARY, T.BOTH, Ty.PISTOL, 200,
		100.0, 1.0, 800, 1, 0, 0.0, 0.0, 0.0, false, 1, 0.0, 0)

	return d
