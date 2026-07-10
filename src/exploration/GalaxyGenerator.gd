extends RefCounted

const SECTOR_TYPES = ["starter", "trade", "frontier", "faction_hq", "danger", "anomaly", "ancient"]

static func generate_galaxy() -> Array:
	var sectors = []
	
	_sectors_from_plan(sectors)
	
	var idx = 0
	for sec in sectors:
		sec["index"] = idx
		idx += 1
	
	_connect_sectors(sectors)
	
	return sectors

static func _sectors_from_plan(sectors: Array) -> void:
	var plan = [
		{name="Starter Nebula", lvl_min=1, lvl_max=10, type="starter", faction="neutral", x=0, y=0},
		{name="Federation Space", lvl_min=10, lvl_max=25, type="trade", faction="federation", x=2, y=0},
		{name="Kaelos Rift", lvl_min=12, lvl_max=22, type="frontier", faction="federation", x=1, y=1},
		{name="Border Worlds", lvl_min=25, lvl_max=40, type="frontier", faction="neutral", x=3, y=-1},
		{name="Dominion Outpost", lvl_min=28, lvl_max=38, type="faction_hq", faction="dominion", x=2, y=-2},
		{name="Zerath Expanse", lvl_min=40, lvl_max=55, type="danger", faction="zerath", x=4, y=0},
		{name="Silent Nebula", lvl_min=42, lvl_max=52, type="anomaly", faction="neutral", x=5, y=1},
		{name="Nomad Drift", lvl_min=45, lvl_max=55, type="faction_hq", faction="void_nomads", x=3, y=2},
		{name="Iron Wastes", lvl_min=55, lvl_max=70, type="danger", faction="dominion", x=5, y=-1},
		{name="Forge of Worlds", lvl_min=58, lvl_max=68, type="faction_hq", faction="dominion", x=4, y=-2},
		{name="Void Rifts", lvl_min=70, lvl_max=85, type="anomaly", faction="void_nomads", x=6, y=0},
		{name="Custodian Gate", lvl_min=72, lvl_max=82, type="faction_hq", faction="ancient", x=7, y=1},
		{name="The Maw", lvl_min=75, lvl_max=85, type="danger", faction="neutral", x=6, y=-1},
		{name="Ancient Core", lvl_min=85, lvl_max=99, type="ancient", faction="ancient", x=8, y=0},
	]
	for entry in plan:
		var sec = entry.duplicate()
		sec["explored"] = sec.type == "starter"
		sec["connections"] = []
		sec["id"] = sec.name.to_lower().replace(" ", "_")
		sectors.append(sec)

static func _connect_sectors(sectors: Array) -> void:
	for i in range(sectors.size()):
		for j in range(i + 1, sectors.size()):
			var a = sectors[i]
			var b = sectors[j]
			var dist = sqrt(pow(a.x - b.x, 2) + pow(a.y - b.y, 2))
			if dist <= 2.0:
				if not a.connections.has(j):
					a.connections.append(j)
				if not b.connections.has(i):
					b.connections.append(i)

static func generate_system(sector: Dictionary, rng: RandomNumberGenerator) -> Array:
	var count = rng.randi_range(5, 12)
	var objects = []
	var object_types = ["planet", "station", "asteroid_field", "anomaly", "enemy_patrol"]
	
	if sector.type == "starter":
		object_types = ["planet", "station", "asteroid_field"]
	elif sector.type == "anomaly":
		object_types.append("anomaly")
		object_types.append("anomaly")
	
	var used_positions = []
	for i in range(count):
		var obj_type = object_types[rng.randi() % object_types.size()]
		var pos = _find_free_position(used_positions, rng)
		if pos == Vector2.ZERO:
			continue
		used_positions.append(pos)
		
		var obj = {
			"type": obj_type,
			"grid_pos": pos,
			"name": _generate_object_name(obj_type, rng),
			"discovered": false,
			"scanned": false,
			"resources": _generate_resources(obj_type, sector.lvl_min, rng),
			"hostile": obj_type == "enemy_patrol"
		}
		
		if obj_type == "planet":
			obj.planet_type = _random_planet_type(rng)
		
		objects.append(obj)
	
	return objects

static func _find_free_position(used: Array, rng: RandomNumberGenerator) -> Vector2:
	for attempt in range(50):
		var pos = Vector2(rng.randi_range(3, 25), rng.randi_range(3, 18))
		var ok = true
		for u in used:
			if HexCoord.hex_distance(pos, u) < 3:
				ok = false
				break
		if ok:
			return pos
	return Vector2.ZERO

static func _random_planet_type(rng: RandomNumberGenerator) -> String:
	var types = ["desert", "volcanic", "ocean", "forest", "gas", "ice"]
	return types[rng.randi() % types.size()]

static func _generate_object_name(type: String, rng: RandomNumberGenerator) -> String:
	var names = {
		"planet": ["Elysium", "Nova Prime", "Kaelos", "Vortex", "Obsidian", "Crystal", "Ember", "Frost", "Verdant", "Abyss"],
		"station": ["Port Haven", "Star Dock", "Nexus Point", "Iron Gate", "Void Station", "Trade Hub"],
		"asteroid_field": ["The Belt", "Crystal Field", "Mineral Ring", "Debris Cloud"],
		"anomaly": ["The Whisper", "Null Zone", "Chronos Rift", "Void Gate", "Singularity"],
		"enemy_patrol": ["Patrol", "Raiders", "Scouts", "War Party"]
	}
	var pool = names.get(type, ["Unknown"])
	var prefix = ""
	if type == "planet":
		prefix = _planet_prefix(rng) + " "
	return prefix + pool[rng.randi() % pool.size()]

static func _planet_prefix(rng: RandomNumberGenerator) -> String:
	var prefixes = ["Alpha", "Beta", "Gamma", "Delta", "Epsilon", "Zeta", "Nova", "Old", "New", "Proxima"]
	return prefixes[rng.randi() % prefixes.size()]

static func _generate_resources(type: String, level: int, rng: RandomNumberGenerator) -> Dictionary:
	var resources = {}
	var pool = []
	match type:
		"planet": pool = ["scrap", "components", "crystals", "organics", "gases"]
		"asteroid_field": pool = ["scrap", "crystals", "ore"]
		"station": pool = ["components", "electronics"]
		"anomaly": pool = ["crystals", "artifacts", "datashards"]
		_: pool = ["scrap"]
	
	var count = rng.randi_range(1, 3)
	for i in range(count):
		var res = pool[rng.randi() % pool.size()]
		resources[res] = resources.get(res, 0) + rng.randi_range(level * 5, level * 15)
	
	return resources
