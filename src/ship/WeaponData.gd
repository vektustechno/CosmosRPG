class_name WeaponData
extends Resource

@export var weapon_id: String = ""
@export var weapon_name: String = ""
@export var damage: int = 10
@export var damage_type: String = "energy"
@export var range: int = 6
@export var ap_cost: int = 2
@export var cooldown: int = 0
@export var accuracy: float = 0.9
@export var aoe_radius: int = 0
@export var status_effect: Dictionary = {}

static func load_all() -> Array:
	var file = FileAccess.open("res://src/data/weapons.json", FileAccess.READ)
	if not file:
		return _defaults()
	var json = JSON.parse_string(file.get_as_text())
	if json is not Array:
		return _defaults()
	
	var result = []
	for entry in json:
		var w = WeaponData.new()
		w.weapon_id = entry.get("weapon_id", "")
		w.weapon_name = entry.get("weapon_name", "Unknown")
		w.damage = entry.get("damage", 10)
		w.damage_type = entry.get("damage_type", "energy")
		w.range = entry.get("range", 6)
		w.ap_cost = entry.get("ap_cost", 2)
		w.cooldown = entry.get("cooldown", 0)
		w.accuracy = entry.get("accuracy", 0.9)
		w.aoe_radius = entry.get("aoe_radius", 0)
		w.status_effect = entry.get("status_effect", {})
		result.append(w)
	return result

static func _defaults() -> Array:
	var w = WeaponData.new()
	w.weapon_id = "laser_mk1"
	w.weapon_name = "Laser Mk1"
	w.damage = 10
	w.damage_type = "energy"
	w.range = 6
	w.ap_cost = 2
	w.accuracy = 0.95
	return [w]
