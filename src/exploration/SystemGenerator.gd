extends RefCounted

static func generate_system_scene(sector: Dictionary) -> StarSystem:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(sector.get("name", "") + str(Time.get_ticks_us()))
	
	var system = StarSystem.new()
	system.generate(sector, rng)
	return system

static func get_system_size(object_count: int) -> Vector2:
	var width = 20
	var height = 15
	if object_count > 8:
		width = 28
		height = 20
	elif object_count > 12:
		width = 35
		height = 25
	return Vector2(width, height)
