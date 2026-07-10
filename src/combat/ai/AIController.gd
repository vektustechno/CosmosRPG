class_name AIController
extends Node

@export var ship: Ship
@export var archetype_id: String = "aggressor"

var archetype: Archetype
var tactics: Array = []
var current_target: Ship
var current_enemies: Array = []
var current_allies: Array = []

func _ready() -> void:
	if not ship:
		ship = get_parent() as Ship
	var archetypes = Archetype.load_all()
	archetype = archetypes.get(archetype_id, archetypes.values()[0])
	_init_tactics()

func _init_tactics() -> void:
	match archetype_id:
		"kamikaze":
			tactics = []
		"aggressor":
			tactics = [Tactic.create_shield_balance(), Tactic.create_focus_fire()]
		"brawler":
			tactics = [Tactic.create_shield_balance(), Tactic.create_focus_fire()]
		"skirmisher":
			tactics = [Tactic.create_kite(), Tactic.create_shield_balance()]
		"sniper":
			tactics = [Tactic.create_overwatch(), Tactic.create_shield_balance()]
		"tank":
			tactics = [Tactic.create_shield_balance(), Tactic.create_fall_back()]
		"shield_support":
			tactics = [Tactic.create_emergency_repair(), Tactic.create_shield_balance()]
		"juggernaut":
			tactics = [Tactic.create_focus_fire(), Tactic.create_shield_balance()]

func evaluate_threats(ships: Array) -> Array:
	var threats = []
	for s in ships:
		if s == ship or s.current_hp <= 0:
			continue
		var dist = HexCoord.hex_distance(ship.grid_pos, s.grid_pos)
		var dps_estimate = _estimate_dps(s)
		var threat = (12.0 / max(dist, 1)) + dps_estimate * 0.1
		if s.current_hp > 0:
			threat *= 1.0 + (s.max_hp - s.current_hp) / float(max(s.max_hp, 1)) * 0.5
		threats.append({"ship": s, "threat": threat, "dist": dist})
	threats.sort_custom(func(a, b): return a.threat > b.threat)
	return threats

func _estimate_dps(s: Ship) -> float:
	var dps = 0.0
	for child in s.get_children():
		if child is WeaponSystem:
			for mount in s.weapon_mounts:
				if mount is WeaponMount and mount.weapon:
					dps += mount.weapon.damage / float(max(mount.weapon.ap_cost, 1))
	return dps

func choose_target(threats: Array) -> Ship:
	if threats.is_empty():
		return null
	return threats[0].get("ship", null)

func get_actions() -> Array:
	var actions = []
	
	current_enemies = _get_enemies()
	current_allies = _get_allies()
	
	if current_enemies.is_empty():
		return actions
	
	var threats = evaluate_threats(current_enemies)
	current_target = choose_target(threats)
	if not current_target:
		return actions
	
	if ship.current_hp <= ship.max_hp * archetype.flee_threshold:
		var retreat = _try_retreat()
		if not retreat.is_empty():
			return retreat
	
	var weapon_sys = _get_weapon_system()
	if not weapon_sys:
		return actions
	
	var dist = HexCoord.hex_distance(ship.grid_pos, current_target.grid_pos)
	
	while ship.action_points > 0:
		var action = _decide_next_action(weapon_sys, dist)
		if action.action_type == AIAction.Type.WAIT:
			break
		actions.append(action)
		ship.action_points -= action.ap_cost
		if action.action_type == AIAction.Type.FIRE:
			break
	
	return actions

func _decide_next_action(weapon_sys: WeaponSystem, dist: int) -> AIAction:
	var mounts = weapon_sys.get_all_fireable_weapons(current_target.grid_pos)
	if not mounts.is_empty() and dist >= archetype.preferred_range_min:
		var action = AIAction.new()
		action.action_type = AIAction.Type.FIRE
		action.target_ship = current_target
		action.weapon_index = mounts[0].index
		action.ap_cost = mounts[0].weapon.ap_cost
		return action
	
	if dist > archetype.preferred_range_max:
		var obstacles = _get_obstacles()
		var path = Pathfinder.find_path(ship.grid_pos, current_target.grid_pos, obstacles)
		if not path.is_empty() and path.size() <= ship.action_points:
			var move_to = path[mini(archetype.preferred_range_max - 1, path.size() - 1)]
			var action = AIAction.new()
			action.action_type = AIAction.Type.MOVE
			action.target_pos = move_to
			action.ap_cost = 1
			ship.grid_pos = move_to
			return action
	
	if dist < archetype.preferred_range_min:
		var obstacles = _get_obstacles()
		var retreat_axial = _find_retreat_position(current_target.grid_pos, obstacles)
		if retreat_axial != ship.grid_pos:
			var action = AIAction.new()
			action.action_type = AIAction.Type.MOVE
			action.target_pos = retreat_axial
			action.ap_cost = 1
			ship.grid_pos = retreat_axial
			return action
	
	var action = AIAction.new()
	action.action_type = AIAction.Type.WAIT
	return action

func _try_retreat() -> Array:
	var actions = []
	var obstacles = _get_obstacles()
	var retreat_pos = _find_retreat_position(current_target.grid_pos, obstacles)
	if retreat_pos != ship.grid_pos:
		var path = Pathfinder.find_path(ship.grid_pos, retreat_pos, obstacles)
		if not path.is_empty():
			var cost = mini(path.size(), ship.action_points)
			var target = path[cost - 1]
			ship.grid_pos = target
			var action = AIAction.new()
			action.action_type = AIAction.Type.MOVE
			action.target_pos = target
			action.ap_cost = cost
			actions.append(action)
	return actions

func _find_retreat_position(from_axial: Vector2, obstacles: Array) -> Vector2:
	var best = ship.grid_pos
	var best_dist = HexCoord.hex_distance(ship.grid_pos, from_axial)
	for neighbor in HexCoord.neighbors(ship.grid_pos):
		if _is_obstacle(neighbor, obstacles):
			continue
		var dist = HexCoord.hex_distance(neighbor, from_axial)
		if dist > best_dist:
			best_dist = dist
			best = neighbor
	return best

func _get_weapon_system() -> WeaponSystem:
	for child in ship.get_children():
		if child is WeaponSystem:
			return child
	return null

func _get_enemies() -> Array:
	var result = []
	if ship.is_player:
		return result
	for s in get_tree().get_nodes_in_group("ships"):
		if s is Ship and s != ship and s.current_hp > 0:
			result.append(s)
	return result

func _get_allies() -> Array:
	return []

func _get_obstacles() -> Array:
	var obs = []
	if Global.hex_grid:
		for entry in Global.hex_grid.hex_map.values():
			if entry.blocked:
				obs.append(entry.axial)
			if entry.occupied != null and entry.occupied != ship:
				obs.append(entry.axial)
	return obs

func _is_obstacle(axial: Vector2, obstacles: Array) -> bool:
	for o in obstacles:
		if o is Vector2 and o == axial:
			return true
	return false
