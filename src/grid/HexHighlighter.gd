extends Node2D

class_name HexHighlighter

var highlights: Dictionary = {}

func highlight_cells(cells: Array, color: Color, layer: int = 1) -> void:
	for cell_data in cells:
		var axial: Vector2
		if cell_data is Vector2:
			axial = cell_data
		elif cell_data is Dictionary:
			axial = cell_data.get("axial", Vector2.ZERO)
		else:
			continue

		var key = "%d,%d" % [int(axial.x), int(axial.y)]
		if key in highlights:
			continue

		var pixel = HexCoord.axial_to_pixel(axial.x, axial.y)
		var hex = Polygon2D.new()
		hex.polygon = HexCoord.hex_corners(pixel)
		hex.color = color
		hex.z_index = layer
		add_child(hex)
		highlights[key] = hex

func clear_highlights() -> void:
	for hex in highlights.values():
		hex.queue_free()
	highlights.clear()

func highlight_path(from_axial: Vector2, to_axial: Vector2, obstacles: Array) -> Array:
	clear_highlights()
	var path = Pathfinder.find_path(from_axial, to_axial, obstacles)
	if not path.is_empty():
		highlight_cells(path, Color(0.2, 0.9, 0.2, 0.4))
	return path

func highlight_reachable(from_axial: Vector2, max_cost: int, obstacles: Array) -> void:
	var reachable = Pathfinder.get_reachable(from_axial, max_cost, obstacles)
	var cells = []
	for key in reachable.keys():
		var parts = key.split(",")
		cells.append(Vector2(int(parts[0]), int(parts[1])))
	if not cells.is_empty():
		highlight_cells(cells, Color(0.2, 0.5, 0.9, 0.25), 1)
