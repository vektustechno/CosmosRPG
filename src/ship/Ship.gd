class_name Ship
extends Node2D

@export var is_player: bool = false
@export var ship_class_id: String = "shuttle"

var ship_class: ShipClassData
var hex_grid_ref: HexGrid

var stats: Dictionary = {}
var current_hp: int
var max_hp: int
var current_shields: Dictionary = {"front": 0, "left": 0, "right": 0, "rear": 0}
var max_shields: Dictionary = {"front": 0, "left": 0, "right": 0, "rear": 0}
var shield_regen: int = 0

var facing: int = 0
var grid_pos: Vector2
var action_points: int = 0
var max_action_points: int = 6

var weapon_mounts: Array = []
var equipped_items: Dictionary = {}

var status_effects: Dictionary = {}

func _ready() -> void:
	hex_grid_ref = Global.hex_grid
	_setup_from_class()
	position = HexCoord.axial_to_pixel(grid_pos.x, grid_pos.y)
	_update_sprite()

func _setup_from_class() -> void:
	var all_classes = ShipClassData.load_all()
	ship_class = all_classes.get(ship_class_id, all_classes.values()[0])
	
	stats = ship_class.get_stats_summary()
	max_hp = ship_class.base_hp
	current_hp = max_hp
	
	var shield_count = ship_class.slots.get("shield", 0)
	if shield_count > 0:
		var shield_hp = ship_class.base_power * 2
		for side in ["front", "left", "right", "rear"]:
			current_shields[side] = shield_hp
			max_shields[side] = shield_hp
		shield_regen = max(1, shield_hp / 10)
	
	max_action_points = ship_class.base_speed + 3
	action_points = max_action_points

func _update_sprite() -> void:
	var sprite = $Sprite2D
	if sprite:
		var color_map = {
			"shuttle": Color(0.5, 0.5, 0.5),
			"fighter": Color(0.8, 0.2, 0.2),
			"corvette": Color(0.2, 0.5, 0.8),
			"frigate": Color(0.2, 0.8, 0.5),
			"cruiser": Color(0.8, 0.5, 0.2),
			"battlecruiser": Color(0.8, 0.2, 0.8),
			"dreadnought": Color(0.9, 0.1, 0.1),
			"ancient_carrier": Color(0.3, 0.9, 0.9)
		}
		sprite.modulate = color_map.get(ship_class_id, Color.WHITE)

func move_to(target_axial: Vector2, path: Array) -> bool:
	var cost = path.size()
	if action_points < cost:
		return false
	
	if path.is_empty():
		return false
	
	grid_pos = target_axial
	position = HexCoord.axial_to_pixel(target_axial.x, target_axial.y)
	action_points -= cost
	
	if hex_grid_ref:
		hex_grid_ref.set_occupied(target_axial, self)
	
	return true

func rotate_to(new_facing: int) -> bool:
	var diff = abs(facing - new_facing)
	if diff > 3:
		diff = 6 - diff
	var cost = diff
	if action_points < cost:
		return false
	
	facing = new_facing
	rotation = deg_to_rad(-facing * 60)
	action_points -= cost
	return true

func take_damage(amount: int, damage_type: String, from_direction: String) -> Dictionary:
	var shield_remaining = current_shields.get(from_direction, 0)
	var hull_damage = amount
	var shield_damage = 0
	
	if damage_type == "true":
		hull_damage = amount
	elif damage_type == "energy":
		if shield_remaining > 0:
			shield_damage = min(shield_remaining, amount * 2)
			hull_damage = max(0, amount - shield_damage / 2)
		hull_damage = int(hull_damage * 0.5)
	elif damage_type == "kinetic":
		if shield_remaining > 0:
			shield_damage = min(shield_remaining, int(amount * 0.5))
			hull_damage = max(0, amount - shield_damage * 2)
	elif damage_type == "explosive":
		if shield_remaining > 0:
			shield_damage = min(shield_remaining, amount)
			hull_damage = max(1, amount - shield_damage)
		hull_damage = int(hull_damage * 0.75)
	elif damage_type == "ion":
		hull_damage = 0
		var disabled = randi() % 2 == 0
		if disabled:
			status_effects["system_disabled"] = 2
	elif damage_type == "emp":
		shield_damage = shield_remaining
		hull_damage = 0
		status_effects["emp"] = 1
	
	current_shields[from_direction] = max(0, shield_remaining - shield_damage)
	current_hp = max(0, current_hp - hull_damage)
	
	var is_crit = randf() < 0.1
	var system_hit = ""
	if is_crit:
		system_hit = _apply_critical_hit()
	
	return {
		"shield_damage": shield_damage,
		"hull_damage": hull_damage,
		"crit": is_crit,
		"system_hit": system_hit,
		"destroyed": current_hp <= 0
	}

func _apply_critical_hit() -> String:
	var systems = ["engine", "weapon", "reactor", "shield_gen", "bridge", "cargo"]
	var hit = systems[randi() % systems.size()]
	status_effects[hit + "_hit"] = 2
	return hit

func regenerate_shields() -> void:
	for side in current_shields.keys():
		var max_sh = max_shields.get(side, 0)
		if current_shields[side] < max_sh:
			current_shields[side] = min(max_sh, current_shields[side] + shield_regen)

func new_turn() -> void:
	action_points = max_action_points
	regenerate_shields()
	_tick_status_effects()

func _tick_status_effects() -> void:
	var expired = []
	for effect in status_effects.keys():
		var turns = status_effects[effect] - 1
		if turns <= 0:
			expired.append(effect)
		else:
			status_effects[effect] = turns
	for e in expired:
		status_effects.erase(e)

func change_ship(new_class_id: String) -> void:
	ship_class_id = new_class_id
	_setup_from_class()
	_update_sprite()
