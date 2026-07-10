class_name GalaxyMap
extends Node2D

var sectors: Array = []
var current_sector_index: int = 0

signal sector_selected(index: int)

func _ready() -> void:
	sectors = GalaxyGenerator.generate_galaxy()

func get_current_sector() -> Dictionary:
	if current_sector_index >= 0 and current_sector_index < sectors.size():
		return sectors[current_sector_index]
	return {}

func travel_to(index: int) -> bool:
	if index < 0 or index >= sectors.size():
		return false
	if not sectors[index].get("explored", false):
		if not sectors[current_sector_index].connections.has(index):
			return false
	sectors[index]["explored"] = true
	current_sector_index = index
	return true

func explore_sector(index: int) -> void:
	if index >= 0 and index < sectors.size():
		sectors[index]["explored"] = true

func get_connected_sectors(index: int) -> Array:
	if index < 0 or index >= sectors.size():
		return []
	var conn = sectors[index].get("connections", [])
	var result = []
	for c in conn:
		if c >= 0 and c < sectors.size():
			result.append(sectors[c])
	return result

func can_travel(from_idx: int, to_idx: int) -> bool:
	if from_idx < 0 or to_idx < 0:
		return false
	if from_idx >= sectors.size() or to_idx >= sectors.size():
		return false
	return sectors[from_idx].connections.has(to_idx)
