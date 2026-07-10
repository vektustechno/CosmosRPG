extends Node

var factions: Dictionary = {}

signal reputation_changed(faction_id: String, new_value: int)

func _ready() -> void:
	_init_factions()

func _init_factions() -> void:
	var data = {
		"federation": {
			"name": "Terran Federation",
			"description": "Standard technologies, trade focus",
			"tiers": {1: 0, 2: 100, 3: 300, 4: 700, 5: 1200},
			"relations": {"zerath": -50, "dominion": -30, "void_nomads": 20, "ancient": 0}
		},
		"zerath": {
			"name": "Zerath Collective",
			"description": "Advanced shields, xenotech",
			"tiers": {1: 0, 2: 100, 3: 300, 4: 700, 5: 1200},
			"relations": {"federation": -50, "dominion": -80, "void_nomads": 50, "ancient": 30}
		},
		"dominion": {
			"name": "Iron Dominion",
			"description": "Armour, weapons, militarism",
			"tiers": {1: 0, 2: 100, 3: 300, 4: 700, 5: 1200},
			"relations": {"federation": -30, "zerath": -80, "void_nomads": -60, "ancient": -20}
		},
		"void_nomads": {
			"name": "Void Nomads",
			"description": "Evasion, warp, stealth",
			"tiers": {1: 0, 2: 100, 3: 300, 4: 700, 5: 1200},
			"relations": {"federation": 20, "zerath": 50, "dominion": -60, "ancient": 40}
		},
		"ancient": {
			"name": "Ancient Custodians",
			"description": "Artifacts, mysteries",
			"tiers": {1: 0, 2: 500, 3: 1000},
			"relations": {"federation": 0, "zerath": 30, "dominion": -20, "void_nomads": 40}
		}
	}
	
	for fid in data.keys():
		var f = FactionData.new()
		f.faction_id = fid
		f.name = data[fid]["name"]
		f.description = data[fid]["description"]
		f.tiers = data[fid]["tiers"]
		f.relations = data[fid]["relations"]
		f.reputation = 0
		factions[fid] = f

func change_reputation(faction_id: String, delta: int, reason: String = "") -> void:
	var faction = factions.get(faction_id)
	if not faction:
		return
	
	var old_rep = faction.reputation
	faction.reputation = clampi(faction.reputation + delta, -2000, 2000)
	reputation_changed.emit(faction_id, faction.reputation)
	
	for other_fid in faction.relations.keys():
		var relation_mod = faction.relations.get(other_fid, 0)
		if relation_mod != 0:
			var other = factions.get(other_fid)
			if other:
				var shared_delta = int(delta * relation_mod / 100.0)
				other.reputation = clampi(other.reputation + shared_delta, -2000, 2000)

func get_faction(faction_id: String) -> FactionData:
	return factions.get(faction_id)

func get_faction_tier(faction_id: String) -> int:
	var faction = factions.get(faction_id)
	if not faction:
		return 0
	var rep = faction.reputation
	var best_tier = 1
	for tier in faction.tiers.keys():
		if rep >= faction.tiers[tier] and tier > best_tier:
			best_tier = tier
	return best_tier

func get_shop_discount(faction_id: String) -> float:
	var tier = get_faction_tier(faction_id)
	return [0.0, 0.0, 0.05, 0.10, 0.15, 0.25][mini(tier, 5)]

func get_available_items(faction_id: String) -> Array:
	var tier = get_faction_tier(faction_id)
	var max_rarity = ["common", "common", "uncommon", "rare", "epic", "legendary"][mini(tier, 5)]
	var items = []
	for bp_id in ["laser_mk1", "shield_mk1", "shield_mk2", "engine_t1", "reactor_mk1", "armor_plating", "repair_drone", "sensor_array"]:
		var item = ItemGenerator.generate_item(bp_id, max_rarity, 1)
		if item:
			items.append(item)
	return items
