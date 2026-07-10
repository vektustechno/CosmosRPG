class_name Tactic
extends Resource

@export var tactic_id: String = ""
@export var priority: int = 5

func evaluate(ship: Ship, allies: Array, enemies: Array) -> bool:
	match tactic_id:
		"flank":
			if allies.size() > 1:
				return true
		"focus_fire":
			var lowest = _find_lowest_hp(enemies)
			if lowest and lowest.current_hp < lowest.max_hp * 0.5:
				return true
		"kite":
			var closest = _find_closest(enemies, ship.grid_pos)
			if closest:
				var dist = HexCoord.hex_distance(ship.grid_pos, closest.grid_pos)
				if dist < 4:
					return true
		"shield_balance":
			for side in ship.current_shields.keys():
				var max_sh = ship.max_shields.get(side, 1)
				if max_sh > 0 and ship.current_shields[side] < max_sh * 0.3:
					return true
		"emergency_repair":
			if ship.current_hp < ship.max_hp * 0.3:
				return true
		"power_surge":
			if ship.stats.get("power", 50) > ship.stats.get("power", 50) * 0.8:
				return true
		"fall_back":
			if ship.current_hp < ship.max_hp * 0.2:
				return true
		"overwatch":
			var closest = _find_closest(enemies, ship.grid_pos)
			if closest:
				var dist = HexCoord.hex_distance(ship.grid_pos, closest.grid_pos)
				if dist > 6:
					return true
	return false

func execute(ship: Ship, target: Ship) -> Array:
	var actions = []
	match tactic_id:
		"flank":
			var flank_pos = _get_flank_position(ship, target)
			if flank_pos != Vector2.ZERO:
				actions.append({"action": "move", "target_pos": flank_pos, "ap_cost": HexCoord.hex_distance(ship.grid_pos, flank_pos)})
		"focus_fire":
			var weapon_sys = _get_weapon_system(ship)
			if weapon_sys and target:
				var mounts = weapon_sys.get_all_fireable_weapons(target.grid_pos)
				if not mounts.is_empty():
					actions.append({"action": "fire", "target_ship": target, "weapon_index": mounts[0].index, "ap_cost": 2})
		"kite":
			var retreat_pos = _get_retreat_position(ship, target)
			if retreat_pos != Vector2.ZERO:
				actions.append({"action": "move", "target_pos": retreat_pos, "ap_cost": HexCoord.hex_distance(ship.grid_pos, retreat_pos)})
		"shield_balance":
			var weakest = "front"
			var weakest_pct = 1.0
			for side in ship.current_shields.keys():
				var max_sh = ship.max_shields.get(side, 1)
				if max_sh > 0:
					var pct = float(ship.current_shields[side]) / float(max_sh)
					if pct < weakest_pct:
						weakest_pct = pct
						weakest = side
			if weakest_pct < 0.3:
				ship.current_shields[weakest] = mini(ship.max_shields.get(weakest, 0), ship.current_shields[weakest] + 20)
		"emergency_repair":
			var heal = int(ship.max_hp * 0.15)
			ship.current_hp = mini(ship.max_hp, ship.current_hp + heal)
		"power_surge":
			ship.stats["power_surge"] = 1.2
		"fall_back":
			var far_pos = _get_furthest_from_all(ship, target)
			if far_pos != Vector2.ZERO:
				actions.append({"action": "move", "target_pos": far_pos, "ap_cost": HexCoord.hex_distance(ship.grid_pos, far_pos)})
		"overwatch":
			ship.status_effects["overwatch"] = 1
	return actions

func _find_lowest_hp(ships: Array) -> Ship:
	var lowest: Ship = null
	for s in ships:
		if s is Ship and s.current_hp > 0:
			if not lowest or s.current_hp < lowest.current_hp:
				lowest = s
	return lowest

func _find_closest(ships: Array, from: Vector2) -> Ship:
	var closest: Ship = null
	var closest_dist = 999
	for s in ships:
		if s is Ship and s.current_hp > 0:
			var d = HexCoord.hex_distance(from, s.grid_pos)
			if d < closest_dist:
				closest_dist = d
				closest = s
	return closest

func _get_flank_position(ship: Ship, target: Ship) -> Vector2:
	if not target or not ship:
		return Vector2.ZERO
	var dir_to_target = HexCoord.neighbors(ship.grid_pos)
	for dir in dir_to_target:
		var d = HexCoord.hex_distance(dir, target.grid_pos)
		var current_d = HexCoord.hex_distance(ship.grid_pos, target.grid_pos)
		if d <= current_d and d > 1:
			return dir
	return Vector2.ZERO

func _get_retreat_position(ship: Ship, target: Ship) -> Vector2:
	if not target or not ship:
		return Vector2.ZERO
	var best = Vector2.ZERO
	var best_dist = 0
	for n in HexCoord.neighbors(ship.grid_pos):
		var d = HexCoord.hex_distance(n, target.grid_pos)
		if d > best_dist:
			best_dist = d
			best = n
	return best

func _get_furthest_from_all(ship: Ship, target: Ship) -> Vector2:
	if not ship:
		return Vector2.ZERO
	var best = Vector2.ZERO
	var best_dist = 0
	for n in HexCoord.neighbors(ship.grid_pos):
		if best_dist < 10:
			best_dist = 10
			best = n
	return best

func _get_weapon_system(ship: Ship) -> WeaponSystem:
	for child in ship.get_children():
		if child is WeaponSystem:
			return child
	return null
