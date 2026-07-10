extends Node

signal level_up(new_level: int)
signal perk_unlocked(perk_id: String)

var xp: int = 0
var level: int = 1
var max_level: int = 99

var stat_points: int = 0
var perks: Array = []
var assigned_stats: Dictionary = {
	"pilot": 0, "gunnery": 0, "engineering": 0, "science": 0, "command": 0
}

static func get_xp_for_level(lvl: int) -> int:
	return int(100 * pow(lvl, 1.5))

func add_xp(amount: int) -> void:
	xp += amount
	while level < max_level and xp >= get_xp_for_level(level):
		xp -= get_xp_for_level(level)
		level += 1
		stat_points += 1
		if level % 10 == 0:
			var perk_id = _generate_perk(level)
			perks.append(perk_id)
			perk_unlocked.emit(perk_id)
		level_up.emit(level)

func assign_stat(stat_name: String) -> bool:
	if stat_points <= 0:
		return false
	if not assigned_stats.has(stat_name):
		return false
	assigned_stats[stat_name] += 1
	stat_points -= 1
	return true

func _generate_perk(lvl: int) -> String:
	var rank = lvl / 10
	var perks_pool = [
		"scan_range_plus", "weapon_damage_plus", "shield_recharge_plus",
		"move_speed_plus", "crit_chance_plus", "repair_efficiency",
		"cargo_capacity", "energy_efficiency", "evasion_plus", "hull_boost"
	]
	return perks_pool[rank % perks_pool.size()]

func get_bonus_from_stats() -> Dictionary:
	return {
		"pilot_bonus": assigned_stats.get("pilot", 0) * 2,
		"gunnery_bonus": assigned_stats.get("gunnery", 0) * 2,
		"engineering_bonus": assigned_stats.get("engineering", 0) * 2,
		"science_bonus": assigned_stats.get("science", 0) * 2,
		"command_bonus": assigned_stats.get("command", 0) * 2
	}

func get_progress_pct() -> float:
	if level >= max_level:
		return 1.0
	return float(xp) / float(get_xp_for_level(level))
