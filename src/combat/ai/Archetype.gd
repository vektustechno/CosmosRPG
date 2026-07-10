class_name Archetype
extends Resource

@export var archetype_id: String = "aggressor"
@export var preferred_range_min: int = 2
@export var preferred_range_max: int = 5
@export var flee_threshold: float = 0.15
@export var aggro_range: int = 12
@export var description: String = ""

static func load_all() -> Dictionary:
	var file = FileAccess.open("res://src/data/archetypes.json", FileAccess.READ)
	if not file:
		return _defaults()
	var json = JSON.parse_string(file.get_as_text())
	if json is not Array:
		return _defaults()
	
	var result = {}
	for entry in json:
		var a = Archetype.new()
		a.archetype_id = entry.get("archetype_id", "")
		a.preferred_range_min = entry.get("preferred_range_min", 2)
		a.preferred_range_max = entry.get("preferred_range_max", 5)
		a.flee_threshold = entry.get("flee_threshold", 0.15)
		a.aggro_range = entry.get("aggro_range", 12)
		a.description = entry.get("description", "")
		result[a.archetype_id] = a
	return result

static func _defaults() -> Dictionary:
	var a = Archetype.new()
	a.archetype_id = "aggressor"
	a.preferred_range_min = 2
	a.preferred_range_max = 5
	a.flee_threshold = 0.15
	a.aggro_range = 12
	return {"aggressor": a}
