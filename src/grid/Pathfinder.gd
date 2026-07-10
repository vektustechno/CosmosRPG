class_name Pathfinder
extends RefCounted

static func find_path(from_axial: Vector2, to_axial: Vector2, obstacles: Array) -> Array:
	if from_axial == to_axial:
		return []
	if _is_obstacle(to_axial, obstacles):
		return []

	var open_set = {}
	var closed_set = {}
	var came_from = {}
	var g_score = {}
	var f_score = {}

	var key = _key(from_axial)
	open_set[key] = from_axial
	g_score[key] = 0
	f_score[key] = HexCoord.hex_distance(from_axial, to_axial)

	while not open_set.is_empty():
		var current_key = _lowest_f(open_set, f_score)
		var current = open_set[current_key]
		open_set.erase(current_key)
		closed_set[current_key] = current

		if current == to_axial:
			return _reconstruct_path(came_from, current)

		for neighbor in HexCoord.neighbors(current):
			var n_key = _key(neighbor)
			if n_key in closed_set:
				continue
			if _is_obstacle(neighbor, obstacles) and neighbor != to_axial:
				continue

			var tentative_g = g_score.get(current_key, INF) + 1
			if tentative_g < g_score.get(n_key, INF):
				came_from[n_key] = current
				g_score[n_key] = tentative_g
				f_score[n_key] = tentative_g + HexCoord.hex_distance(neighbor, to_axial)
				if n_key not in open_set:
					open_set[n_key] = neighbor

	return []

static func get_reachable(from_axial: Vector2, max_cost: int, obstacles: Array) -> Dictionary:
	var result = {}

	var open_set = {}
	var closed_set = {}
	var g_score = {}

	var key = _key(from_axial)
	open_set[key] = from_axial
	g_score[key] = 0

	while not open_set.is_empty():
		var current_key = _lowest_f(open_set, g_score)
		var current = open_set[current_key]
		var current_g = g_score[current_key]
		open_set.erase(current_key)
		closed_set[current_key] = current
		result[current_key] = current_g

		if current_g >= max_cost:
			continue

		for neighbor in HexCoord.neighbors(current):
			var n_key = _key(neighbor)
			if n_key in closed_set:
				continue
			if _is_obstacle(neighbor, obstacles):
				continue

			var tentative_g = current_g + 1
			if tentative_g < g_score.get(n_key, INF) and tentative_g <= max_cost:
				g_score[n_key] = tentative_g
				if n_key not in open_set:
					open_set[n_key] = neighbor

	return result

static func _key(axial: Vector2) -> String:
	return "%d,%d" % [int(axial.x), int(axial.y)]

static func _is_obstacle(axial: Vector2, obstacles: Array) -> bool:
	for obs in obstacles:
		if obs is Vector2 and obs == axial:
			return true
		if obs is Dictionary and obs.get("axial") == axial:
			return true
	return false

static func _lowest_f(set: Dictionary, scores: Dictionary) -> String:
	var best_key = ""
	var best_score = INF
	for key in set.keys():
		var s = scores.get(key, INF)
		if s < best_score:
			best_score = s
			best_key = key
	return best_key

static func _reconstruct_path(came_from: Dictionary, current: Vector2) -> Array:
	var path = [current]
	while _key(current) in came_from:
		current = came_from[_key(current)]
		path.push_front(current)
	return path
