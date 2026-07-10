class_name ShipClassData
extends Resource

@export var class_id: String = ""
@export var class_name: String = ""
@export var description: String = ""
@export var sector_unlock: int = 1

@export var base_hp: int = 100
@export var base_speed: int = 3
@export var base_turn_rate: int = 60
@export var base_power: int = 100

@export var slots: Dictionary = {
	"weapon": 2, "shield": 0, "engine": 1,
	"reactor": 1, "armor": 0, "utility": 1, "special": 0
}

@export var passive_bonus: Dictionary = {}

@export var price: int = 0
@export var required_reputation: Dictionary = {}

static func load_all() -> Dictionary:
	var file = FileAccess.open("res://src/data/ship_classes.json", FileAccess.READ)
	if not file:
		return {}
	var json = JSON.parse_string(file.get_as_text())
	if json is not Array:
		return {}

	var result = {}
	for entry in json:
		var cls = ShipClassData.new()
		cls.class_id = entry.get("class_id", "")
		cls.class_name = entry.get("class_name", "")
		cls.description = entry.get("description", "")
		cls.sector_unlock = entry.get("sector_unlock", 1)
		cls.base_hp = entry.get("base_hp", 100)
		cls.base_speed = entry.get("base_speed", 3)
		cls.base_turn_rate = entry.get("base_turn_rate", 60)
		cls.base_power = entry.get("base_power", 100)
		cls.slots = entry.get("slots", {})
		cls.passive_bonus = entry.get("passive_bonus", {})
		cls.price = entry.get("price", 0)
		cls.required_reputation = entry.get("required_reputation", {})
		result[cls.class_id] = cls
	return result

func get_stats_summary() -> Dictionary:
	return {
		"hp": base_hp,
		"speed": base_speed,
		"turn_rate": base_turn_rate,
		"power": base_power,
		"slots": slots
	}
