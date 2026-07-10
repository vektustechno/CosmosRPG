extends Node2D

@export var grid_size: Vector2i = Vector2i(20, 20)
@export var hex_size: float = 16.0

var hex_map: Dictionary = {}
var highlight_layer: Node2D

func _ready() -> void:
	_generate_grid()

func _generate_grid() -> void:
	for q in range(grid_size.x):
		for r in range(grid_size.y):
			var axial = Vector2(q - r / 2, r)
			var pixel_pos = HexCoord.axial_to_pixel(axial.x, axial.y)
			var hex = Polygon2D.new()
			hex.polygon = HexCoord.hex_corners(pixel_pos)
			hex.color = _get_hex_color(q, r)
			hex.z_index = 0
			add_child(hex)

			var entry = {
				"axial": axial,
				"pixel": pixel_pos,
				"polygon": hex,
				"blocked": false,
				"occupied": null
			}
			hex_map[axial] = entry

func _get_hex_color(q: int, r: int) -> Color:
	var is_even = (q + r) % 2 == 0
	if is_even:
		return Color(0.15, 0.15, 0.22)
	else:
		return Color(0.12, 0.12, 0.18)

func get_hex_at(axial: Vector2) -> Dictionary:
	return hex_map.get(axial, {})

func get_hex_by_pixel(pos: Vector2) -> Dictionary:
	var axial = HexCoord.pixel_to_axial(pos)
	return get_hex_at(axial)

func set_blocked(axial: Vector2, blocked: bool) -> void:
	var entry = get_hex_at(axial)
	if not entry.is_empty():
		entry.blocked = blocked
		if blocked:
			entry.polygon.color = Color(0.3, 0.05, 0.05)
		else:
			entry.polygon.color = _get_hex_color(int(axial.x), int(axial.y))

func set_occupied(axial: Vector2, ship: Node2D) -> void:
	var entry = get_hex_at(axial)
	if not entry.is_empty():
		entry.occupied = ship

func get_all_hexes() -> Array:
	return hex_map.values()

func get_hexes_in_range(from_axial: Vector2, range: int) -> Array:
	var result = []
	for q in range(int(from_axial.x) - range, int(from_axial.x) + range + 1):
		for r in range(int(from_axial.y) - range, int(from_axial.y) + range + 1):
			var axial = Vector2(q, r)
			if HexCoord.hex_distance(from_axial, axial) <= range:
				var entry = get_hex_at(axial)
				if not entry.is_empty():
					result.append(entry)
	return result

func get_occupied_hexes() -> Array:
	var result = []
	for entry in hex_map.values():
		if entry.occupied != null:
			result.append(entry.axial)
	return result

func get_blocked_hexes() -> Array:
	var result = []
	for entry in hex_map.values():
		if entry.blocked:
			result.append(entry.axial)
	return result

func get_obstacle_hexes() -> Array:
	var result = []
	for entry in hex_map.values():
		if entry.blocked or entry.occupied != null:
			result.append(entry.axial)
	return result
