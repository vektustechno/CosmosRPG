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
var equipped_items: Dictionary = {
	"weapon": [], "shield": [], "engine": null, "reactor": null,
	"armor": [], "utility": [], "special": null
}
var inventory: Inventory = Inventory.new()

var status_effects: Dictionary = {}

var set_counts: Dictionary = {}

func _ready() -> void:
	hex_grid_ref = Global.hex_grid
	add_to_group("ships")
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
	
	var weapon_count = ship_class.slots.get("weapon", 2)
	weapon_mounts.clear()
	var all_weapons = WeaponData.load_all()
	var arc_types = ["forward", "forward", "broadside_left", "broadside_right", "turret", "turret", "rear", "forward"]
	for i in range(weapon_count):
		var mount = WeaponMount.new()
		mount.mount_id = "mount_%d" % i
		mount.arc_type = arc_types[i % arc_types.size()]
		if i == 0 and not all_weapons.is_empty():
			mount.weapon = all_weapons[0]
		mount.arc_angle = 90.0 if mount.arc_type == "forward" or mount.arc_type == "rear" else 180.0
		if mount.arc_type == "turret":
			mount.arc_angle = 360.0
		weapon_mounts.append(mount)
	
	var weapon_system = WeaponSystem.new()
	weapon_system.ship = self
	add_child(weapon_system)
	
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
	var attack = {
		"damage": amount,
		"damage_type": damage_type,
		"crit_bonus": 0.0
	}
	var result = DamageCalculator.calculate_damage(attack, self, from_direction)
	return result

func calc_stats() -> void:
	stats = ship_class.get_stats_summary()
	
	for slot_name in equipped_items.keys():
		var items_in_slot = equipped_items[slot_name]
		if items_in_slot is Array:
			for item in items_in_slot:
				if item is EquipmentData:
					_apply_item_stats(item)
		elif items_in_slot is EquipmentData:
			_apply_item_stats(items_in_slot)
	
	max_hp = ship_class.base_hp + stats.get("hull_bonus", 0) + stats.get("max_hp_bonus", 0)
	current_hp = mini(current_hp, max_hp)
	
	var shield_count = ship_class.slots.get("shield", 0)
	if shield_count > 0:
		var base_shield = ship_class.base_power * 2 + stats.get("shield_capacity_bonus", 0)
		var shield_mult = 1.0 + stats.get("shield_capacity", 0) / 100.0
		base_shield = int(base_shield * shield_mult)
		for side in ["front", "left", "right", "rear"]:
			max_shields[side] = base_shield
		shield_regen = max(1, base_shield / 10) + stats.get("shield_regen_bonus", 0)
		shield_regen = int(shield_regen * (1.0 + stats.get("shield_recharge", 0) / 100.0))
	
	max_action_points = ship_class.base_speed + 3 + stats.get("speed_bonus", 0)
	
	_calc_set_bonuses()

func _apply_item_stats(item: EquipmentData) -> void:
	var total = item.get_total_stats()
	for key in total.keys():
		stats[key] = stats.get(key, 0) + total[key]

func _calc_set_bonuses() -> void:
	set_counts.clear()
	var set_pieces = {}
	
	for slot_name in equipped_items.keys():
		var items_in_slot = equipped_items[slot_name]
		if items_in_slot is Array:
			for item in items_in_slot:
				if item is EquipmentData and item.set_id != "":
					if not set_pieces.has(item.set_id):
						set_pieces[item.set_id] = []
					set_pieces[item.set_id].append(item.set_piece)
		elif items_in_slot is EquipmentData and items_in_slot.set_id != "":
			if not set_pieces.has(items_in_slot.set_id):
				set_pieces[items_in_slot.set_id] = []
			set_pieces[items_in_slot.set_id].append(items_in_slot.set_piece)
	
	var sets_data = _load_sets_data()
	for set_id in set_pieces.keys():
		var count = set_pieces[set_id].size()
		set_counts[set_id] = count
		var set_info = sets_data.get(set_id, {})
		var bonuses = set_info.get("bonuses", {})
		for piece_count_str in bonuses.keys():
			var piece_count = int(piece_count_str)
			if count >= piece_count:
				var bonus = bonuses[piece_count_str]
				for key in bonus.keys():
					if key == "description":
						continue
					stats[key] = stats.get(key, 0) + (bonus[key] if typeof(bonus[key]) == TYPE_INT or typeof(bonus[key]) == TYPE_FLOAT else 0)

func _load_sets_data() -> Dictionary:
	var file = FileAccess.open("res://src/data/set_bonuses.json", FileAccess.READ)
	if not file:
		return {}
	return JSON.parse_string(file.get_as_text()) or {}

func equip(item: EquipmentData, slot_name: String, slot_index: int = -1) -> bool:
	if not inventory.has_item_ref(item):
		return false
	
	var max_count = ship_class.slots.get(slot_name, 0)
	if slot_name in ["weapon", "armor", "utility"]:
		var current = equipped_items.get(slot_name, [])
		if current.size() >= max_count:
			return false
		if slot_index >= 0 and slot_index < current.size():
			var old = current[slot_index]
			if old:
				unequip(slot_name, slot_index)
			current[slot_index] = item
		else:
			if not inventory.remove_item_by_ref(item):
				return false
			current.append(item)
	elif slot_name in ["shield", "engine", "reactor", "special"]:
		if equipped_items.get(slot_name) != null:
			return false
		if not inventory.remove_item_by_ref(item):
			return false
		equipped_items[slot_name] = item
	
	calc_stats()
	return true

func unequip(slot_name: String, slot_index: int = -1) -> bool:
	if slot_name in ["weapon", "armor", "utility"]:
		var current = equipped_items.get(slot_name, [])
		var item = null
		if slot_index >= 0 and slot_index < current.size():
			item = current[slot_index]
			if item:
				current[slot_index] = null
		if item:
			inventory.add_item(item)
			calc_stats()
			return true
	elif slot_name in ["shield", "engine", "reactor", "special"]:
		var item = equipped_items.get(slot_name)
		if item:
			equipped_items[slot_name] = null
			inventory.add_item(item)
			calc_stats()
			return true
	return false

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
