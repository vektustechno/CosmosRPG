class_name ItemGenerator
extends RefCounted

static func generate_item(blueprint_id: String, rarity: String = "common", level: int = 1) -> EquipmentData:
	var all_blueprints = _load_blueprints()
	var bp = _find_blueprint(all_blueprints, blueprint_id)
	if bp.is_empty():
		return null
	
	var item = EquipmentData.new()
	item.item_id = bp.get("item_id", "")
	item.item_name = bp.get("item_name", "Unknown")
	item.item_type = bp.get("item_type", "weapon")
	item.rarity = rarity
	item.level = level
	item.base_stats = bp.get("base_stats", {}).duplicate()
	
	_scale_stats(item, level)
	_add_affixes(item)
	_try_set_assignment(item)
	
	return item

static func generate_random_drop(level: int = 1, quality_bias: float = 0.5) -> EquipmentData:
	var blueprints = _load_blueprints()
	if blueprints.is_empty():
		return null
	
	var bp = blueprints[randi() % blueprints.size()]
	var rarity = _roll_rarity(level, quality_bias)
	return generate_item(bp.get("item_id", ""), rarity, level)

static func _roll_rarity(level: int, bias: float) -> String:
	var roll = randf() + bias * 0.3
	var rarities = [
		["broken", 0.1], ["common", 0.4], ["uncommon", 0.3],
		["rare", 0.12], ["epic", 0.05], ["legendary", 0.02],
		["ancient", 0.008], ["transcendent", 0.002]
	]
	if level < 20:
		rarities = [["broken", 0.2], ["common", 0.5], ["uncommon", 0.25], ["rare", 0.05]]
	elif level < 40:
		rarities = [["broken", 0.05], ["common", 0.35], ["uncommon", 0.35], ["rare", 0.2], ["epic", 0.05]]
	elif level < 60:
		rarities = [["common", 0.2], ["uncommon", 0.3], ["rare", 0.3], ["epic", 0.15], ["legendary", 0.05]]
	elif level < 80:
		rarities = [["uncommon", 0.15], ["rare", 0.35], ["epic", 0.3], ["legendary", 0.15], ["ancient", 0.05]]
	else:
		rarities = [["rare", 0.2], ["epic", 0.3], ["legendary", 0.3], ["ancient", 0.15], ["transcendent", 0.05]]
	
	var cumulative = 0.0
	for r in rarities:
		cumulative += r[1]
		if roll < cumulative:
			return r[0]
	return "common"

static func _scale_stats(item: EquipmentData, level: int) -> void:
	var scale = 1.0 + (level - 1) * 0.1
	for key in item.base_stats.keys():
		if key in ["accuracy", "aoe_radius"]:
			continue
		item.base_stats[key] = int(item.base_stats[key] * scale)

static func _add_affixes(item: EquipmentData) -> void:
	var affix_count = item.get_affix_count()
	if affix_count <= 0:
		return
	
	var all_affixes = _load_affixes()
	var compatible = []
	for a in all_affixes:
		if item.item_type in a.get("compatible_types", []):
			compatible.append(a)
	
	if compatible.is_empty():
		return
	
	for i in range(min(affix_count, 5)):
		var chosen = compatible[randi() % compatible.size()]
		var affix = AffixData.new()
		affix.affix_id = chosen.get("affix_id", "")
		affix.affix_name = chosen.get("affix_name", "")
		affix.tier = chosen.get("tier", 1)
		affix.stat_modifiers = chosen.get("stat_modifiers", {}).duplicate()
		affix.compatible_types = chosen.get("compatible_types", [])
		_scale_affix(affix, item.level)
		item.affixes.append(affix)

static func _scale_affix(affix: AffixData, level: int) -> void:
	var scale = 1.0 + (level - 1) * 0.05
	for key in affix.stat_modifiers.keys():
		if typeof(affix.stat_modifiers[key]) == TYPE_INT or typeof(affix.stat_modifiers[key]) == TYPE_FLOAT:
			if affix.stat_modifiers[key] > 1:
				affix.stat_modifiers[key] = int(affix.stat_modifiers[key] * scale)

static func _try_set_assignment(item: EquipmentData) -> void:
	if item.rarity == "broken" or item.rarity == "common":
		return
	if randf() > 0.08:
		return
	
	var sets_data = _load_sets()
	if sets_data.is_empty():
		return
	
	var set_ids = sets_data.keys()
	var chosen_id = set_ids[randi() % set_ids.size()]
	var set_info = sets_data[chosen_id]
	var compatible_pieces = set_info.get("pieces", [])
	
	var item_slot_map = {"weapon": "weapon", "shield": "shield", "engine": "engine", "reactor": "reactor", "armor": "armor", "utility": "utility", "special": "special"}
	var mapped = item_slot_map.get(item.item_type, "")
	if mapped in compatible_pieces:
		item.set_id = chosen_id
		item.set_piece = mapped

static func _find_blueprint(blueprints: Array, blueprint_id: String) -> Dictionary:
	for bp in blueprints:
		if bp.get("item_id", "") == blueprint_id:
			return bp
	return {}

static func _load_blueprints() -> Array:
	var file = FileAccess.open("res://src/data/item_blueprints.json", FileAccess.READ)
	if not file:
		return []
	return JSON.parse_string(file.get_as_text()) or []

static func _load_affixes() -> Array:
	var file = FileAccess.open("res://src/data/affixes.json", FileAccess.READ)
	if not file:
		return []
	return JSON.parse_string(file.get_as_text()) or []

static func _load_sets() -> Dictionary:
	var file = FileAccess.open("res://src/data/set_bonuses.json", FileAccess.READ)
	if not file:
		return {}
	return JSON.parse_string(file.get_as_text()) or {}
