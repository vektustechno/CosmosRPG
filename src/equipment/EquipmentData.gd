class_name EquipmentData
extends Resource

@export var item_id: String = ""
@export var item_name: String = ""
@export var item_type: String = "weapon"
@export var rarity: String = "common"
@export var level: int = 1

@export var base_stats: Dictionary = {}
@export var affixes: Array = []

@export var set_id: String = ""
@export var set_piece: String = ""

var _rarity_tiers = {
	"broken": 1, "common": 2, "uncommon": 3, "rare": 4,
	"epic": 5, "legendary": 6, "ancient": 7, "transcendent": 8
}

func get_rarity_tier() -> int:
	return _rarity_tiers.get(rarity, 2)

func get_affix_count() -> int:
	return max(0, get_rarity_tier() - 1)

func get_display_name() -> String:
	var prefix = ""
	var suffix = ""
	for a in affixes:
		if a is AffixData:
			if a.affix_name.begins_with("Of ") or a.affix_name.begins_with("of "):
				suffix = " " + a.affix_name
			else:
				prefix = a.affix_name + " "
	
	if set_id != "":
		return "%s%s%s [%s]" % [prefix, item_name, suffix, set_id.capitalize()]
	return "%s%s%s" % [prefix, item_name, suffix]

func get_total_stats() -> Dictionary:
	var total = base_stats.duplicate()
	for a in affixes:
		if a is AffixData:
			for key in a.stat_modifiers:
				total[key] = total.get(key, 0) + a.stat_modifiers[key]
	return total
