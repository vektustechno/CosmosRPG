extends RefCounted

static func can_upgrade(item: EquipmentData, player_credits: int, player_resources: Dictionary) -> bool:
	if item.level >= 20:
		return false
	var cost = _get_upgrade_cost(item)
	return player_credits >= cost.credits and _has_resources(player_resources, cost.resources)

static func upgrade(item: EquipmentData, player_credits: int, player_resources: Dictionary) -> Dictionary:
	if not can_upgrade(item, player_credits, player_resources):
		return {"success": false}
	
	var cost = _get_upgrade_cost(item)
	item.level += 1
	
	var result = {"success": true, "new_level": item.level, "new_affix": false}
	
	if item.level == 10 or item.level == 20:
		var affix = _generate_new_affix(item)
		if affix:
			item.affixes.append(affix)
			result.new_affix = true
			result.affix_name = affix.affix_name
	
	return result

static func _get_upgrade_cost(item: EquipmentData) -> Dictionary:
	var level = item.level
	return {
		"credits": level * level * 50,
		"resources": {"scrap": level * 5, "components": max(1, level / 5)}
	}

static func _has_resources(player_resources: Dictionary, required: Dictionary) -> bool:
	for key in required.keys():
		if player_resources.get(key, 0) < required[key]:
			return false
	return true

static func _generate_new_affix(item: EquipmentData) -> AffixData:
	var file = FileAccess.open("res://src/data/affixes.json", FileAccess.READ)
	if not file:
		return null
	var all_affixes = JSON.parse_string(file.get_as_text()) or []
	var compatible = []
	for a in all_affixes:
		if item.item_type in a.get("compatible_types", []):
			compatible.append(a)
	if compatible.is_empty():
		return null
	
	var chosen = compatible[randi() % compatible.size()]
	var affix = AffixData.new()
	affix.affix_id = chosen.get("affix_id", "")
	affix.affix_name = chosen.get("affix_name", "")
	affix.tier = chosen.get("tier", 1)
	affix.stat_modifiers = chosen.get("stat_modifiers", {}).duplicate()
	return affix
