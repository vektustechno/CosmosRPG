extends Node

var player_data: Dictionary = {
	"ship_class": "shuttle",
	"level": 1,
	"xp": 0,
	"credits": 1000,
	"inventory": [],
	"equipped": {},
	"crew": [],
	"skill_tree": {},
	"faction_reputation": {},
	"completed_missions": [],
	"active_missions": [],
	"discovered_sectors": [],
	"resources": {},
	"playtime": 0.0
}

func save(slot_id: int = 0) -> bool:
	var file_path = "user://save_%d.json" % slot_id
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(player_data, "\t"))
	return true

func load(slot_id: int = 0) -> bool:
	var file_path = "user://save_%d.json" % slot_id
	if not FileAccess.file_exists(file_path):
		return false
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return false
	var data = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		player_data = data
		return true
	return false

func get_save_list() -> Array:
	var saves = []
	for i in range(3):
		var path = "user://save_%d.json" % i
		if FileAccess.file_exists(path):
			var file = FileAccess.open(path, FileAccess.READ)
			var data = JSON.parse_string(file.get_as_text())
			saves.append({
				"slot": i,
				"level": data.get("level", 1),
				"playtime": data.get("playtime", 0.0),
				"sector": data.get("current_sector", "unknown")
			})
		else:
			saves.append({"slot": i, "empty": true})
	return saves
