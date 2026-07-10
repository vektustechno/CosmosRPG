class_name StarSystem
extends Node2D

var system_objects: Array = []
var sector_data: Dictionary = {}
var is_generated: bool = false

signal system_entered
signal object_discovered(object_index: int)
signal object_scanned(object_index: int)

func generate(sector: Dictionary, rng: RandomNumberGenerator) -> void:
	sector_data = sector
	system_objects = GalaxyGenerator.generate_system(sector, rng)
	is_generated = true
	system_entered.emit()

func get_objects() -> Array:
	return system_objects

func get_object(index: int) -> Dictionary:
	if index >= 0 and index < system_objects.size():
		return system_objects[index]
	return {}

func get_object_at(axial: Vector2) -> Dictionary:
	for obj in system_objects:
		if obj.get("grid_pos", Vector2.ZERO) == axial:
			return obj
	return {}

func discover_object(index: int) -> void:
	var obj = get_object(index)
	if not obj.is_empty():
		obj["discovered"] = true
		object_discovered.emit(index)

func scan_object(index: int, scan_power: int) -> Dictionary:
	var obj = get_object(index)
	if obj.is_empty():
		return {"success": false}
	
	if obj.get("scanned", false):
		return {"success": true, "already_scanned": true}
	
	obj["scanned"] = true
	object_scanned.emit(index)
	
	var result = {
		"success": true,
		"name": obj.get("name", "Unknown"),
		"type": obj.get("type", "unknown"),
		"resources": obj.get("resources", {}),
		"hostile": obj.get("hostile", false)
	}
	
	if obj.has("planet_type"):
		result["planet_type"] = obj["planet_type"]
	
	if scan_power > 10:
		var hidden = _get_hidden_details(obj)
		for key in hidden.keys():
			result[key] = hidden[key]
	
	return result

func _get_hidden_details(obj: Dictionary) -> Dictionary:
	var hidden = {}
	if obj.get("type") == "anomaly":
		hidden["anomaly_type"] = ["gravitational", "temporal", "energy", "void"][randi() % 4]
		hidden["danger_level"] = randi() % 5 + 1
	if obj.get("type") == "planet":
		var poi_pool = ["ruins", "crashed_ship", "alien_fauna", "mineral_vein", "signal_source"]
		hidden["points_of_interest"] = [poi_pool[randi() % poi_pool.size()]]
	return hidden
