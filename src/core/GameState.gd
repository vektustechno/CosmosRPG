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
	"playtime": 0.0,
	"current_sector": "sector_1"
}

func _process(delta: float) -> void:
	player_data["playtime"] += delta

func save(slot_id: int = 0) -> bool:
	_sync_from_game()
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
		_restore_to_game()
		return true
	return false

func auto_save() -> void:
	save(0)

func _sync_from_game() -> void:
	if not Global.player_ship:
		return
	
	player_data["ship_class"] = Global.player_ship.ship_class_id
	
	var lvl_sys = _find_level_system()
	if lvl_sys:
		player_data["level"] = lvl_sys.level
		player_data["xp"] = lvl_sys.xp
	
	var inv = Global.player_ship.inventory
	if inv:
		player_data["credits"] = inv.credits
		player_data["resources"] = inv.resources.duplicate()
		player_data["inventory"] = _serialize_inventory(inv)
	
	var eq = Global.player_ship.equipped_items
	player_data["equipped"]["weapon"] = _serialize_equipped_slot(eq.get("weapon", []))
	player_data["equipped"]["shield"] = _serialize_item(eq.get("shield"))
	player_data["equipped"]["engine"] = _serialize_item(eq.get("engine"))
	player_data["equipped"]["reactor"] = _serialize_item(eq.get("reactor"))
	player_data["equipped"]["armor"] = _serialize_equipped_slot(eq.get("armor", []))
	player_data["equipped"]["utility"] = _serialize_equipped_slot(eq.get("utility", []))
	player_data["equipped"]["special"] = _serialize_item(eq.get("special"))
	
	var fs = _find_faction_system()
	if fs:
		var reps = {}
		for fid in fs.factions.keys():
			var f = fs.get_faction(fid)
			if f:
				reps[fid] = f.reputation
		player_data["faction_reputation"] = reps
	
	if Global.mission_manager:
		player_data["completed_missions"] = Global.mission_manager.completed_missions.duplicate()
		var active = []
		for m in Global.mission_manager.active_missions:
			if m is MissionData:
				active.append(m.mission_id)
		player_data["active_missions"] = active

func _restore_to_game() -> void:
	if not Global.player_ship:
		return
	
	Global.player_ship.change_ship(player_data.get("ship_class", "shuttle"))
	
	var lvl_sys = _find_level_system()
	if lvl_sys:
		lvl_sys.level = player_data.get("level", 1)
		lvl_sys.xp = player_data.get("xp", 0)
	
	var inv = Global.player_ship.inventory
	if inv:
		inv.credits = player_data.get("credits", 1000)
		inv.resources = player_data.get("resources", {}).duplicate()
		_restore_inventory(inv, player_data.get("inventory", []))
		_restore_equipped(player_data.get("equipped", {}))

func _serialize_inventory(inv: Inventory) -> Array:
	var items = []
	for i in range(inv.items.size()):
		var item = inv.get_item(i)
		if item:
			items.append(_serialize_item(item))
	return items

func _serialize_item(item) -> Dictionary:
	if not item:
		return {}
	return {
		"item_id": item.item_id,
		"item_name": item.item_name,
		"item_type": item.item_type,
		"rarity": item.rarity,
		"level": item.level,
		"set_id": item.set_id,
		"set_piece": item.set_piece,
		"base_stats": item.base_stats.duplicate(),
		"affixes": _serialize_affixes(item.affixes)
	}

func _serialize_affixes(affixes: Array) -> Array:
	var result = []
	for a in affixes:
		if a is AffixData:
			result.append({
				"affix_name": a.affix_name,
				"tier": a.tier,
				"stat_modifiers": a.stat_modifiers.duplicate()
			})
	return result

func _serialize_equipped_slot(arr: Array) -> Array:
	var result = []
	for item in arr:
		result.append(_serialize_item(item))
	return result

func _restore_inventory(inv: Inventory, items_data: Array) -> void:
	inv.items.clear()
	for d in items_data:
		var item = _deserialize_item(d)
		if item:
			inv.items.append(item)

func _restore_equipped(equipped_data: Dictionary) -> void:
	if not Global.player_ship:
		return
	var eq = Global.player_ship.equipped_items
	for slot_name in ["weapon", "armor", "utility"]:
		var data_arr = equipped_data.get(slot_name, [])
		var restored = []
		for d in data_arr:
			var item = _deserialize_item(d)
			if item:
				restored.append(item)
		eq[slot_name] = restored
	for slot_name in ["shield", "engine", "reactor", "special"]:
		var d = equipped_data.get(slot_name, {})
		eq[slot_name] = _deserialize_item(d)
	Global.player_ship.calc_stats()

func _deserialize_item(d: Dictionary) -> EquipmentData:
	if d.is_empty():
		return null
	var item = EquipmentData.new()
	item.item_id = d.get("item_id", "")
	item.item_name = d.get("item_name", "")
	item.item_type = d.get("item_type", "")
	item.rarity = d.get("rarity", "common")
	item.level = d.get("level", 1)
	item.set_id = d.get("set_id", "")
	item.set_piece = d.get("set_piece", "")
	item.base_stats = d.get("base_stats", {}).duplicate()
	for a_data in d.get("affixes", []):
		var affix = AffixData.new()
		affix.affix_name = a_data.get("affix_name", "")
		affix.tier = a_data.get("tier", 1)
		affix.stat_modifiers = a_data.get("stat_modifiers", {}).duplicate()
		item.affixes.append(affix)
	return item

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

func _find_level_system():
	var root = Engine.get_main_loop().root
	for child in root.get_children():
		if child is LevelSystem:
			return child
	return null

func _find_faction_system() -> FactionSystem:
	var root = Engine.get_main_loop().root
	for child in root.get_children():
		if child is FactionSystem:
			return child
	return null
