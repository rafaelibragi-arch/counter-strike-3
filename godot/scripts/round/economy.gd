class_name Economy
extends RefCounted
## Static CS-like economy helpers.

const STARTING_MONEY := 800
const MAX_MONEY := 16000
const AWARD_PLANT := 300
const AWARD_DEFUSE := 300
const AWARD_WIN := 3250

## Loss streak bonuses (index = consecutive losses, capped).
const LOSS_BONUSES := [1400, 1900, 2400, 2900, 3400]


static func loss_bonus(streak: int) -> int:
	var i := clampi(streak, 0, LOSS_BONUSES.size() - 1)
	return LOSS_BONUSES[i]


static func clamp_money(amount: int) -> int:
	return clampi(amount, 0, MAX_MONEY)


static func award_kill(weapon: WeaponDefinition) -> int:
	if weapon == null:
		return 300
	return weapon.kill_award


static func apply_round_end(combatant: Combatant, won: bool, loss_streak: int) -> int:
	if combatant == null:
		return 0
	var gain := AWARD_WIN if won else loss_bonus(loss_streak)
	combatant.add_money(gain)
	return gain
