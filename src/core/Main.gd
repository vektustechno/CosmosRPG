extends Control

@onready var game_world: Node2D = $GameWorld
@onready var hex_grid: HexGrid = $GameWorld/HexGrid
@onready var camera: Camera2D = $GameWorld/Camera2D
@onready var highlighter: HexHighlighter = $GameWorld/HexHighlighter
@onready var title_label: Label = $UILayer/TitleLabel

var dragging: bool = false
var drag_start: Vector2
var camera_start: Vector2
var zoom_level: float = 1.0

var player_ship: Ship
var selected_hex: Vector2 = Vector2.ZERO

func _ready() -> void:
	title_label.hide()
	Global.hex_grid = hex_grid
	_spawn_player_ship()

func _spawn_player_ship() -> void:
	var ship_scene = preload("res://src/ship/Ship.tscn")
	player_ship = ship_scene.instantiate()
	player_ship.is_player = true
	player_ship.ship_class_id = "shuttle"
	player_ship.grid_pos = Vector2(5, 5)
	game_world.add_child(player_ship)
	Global.player_ship = player_ship

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			if dragging:
				drag_start = get_global_mouse_position()
				camera_start = camera.position

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_level = clamp(zoom_level * 0.9, 0.3, 3.0)
			camera.zoom = Vector2(zoom_level, zoom_level)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_level = clamp(zoom_level * 1.1, 0.3, 3.0)
			camera.zoom = Vector2(zoom_level, zoom_level)

		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_on_click()

	if event is InputEventMouseMotion and dragging:
		var delta = get_global_mouse_position() - drag_start
		camera.position = camera_start - delta * camera.zoom.x

func _on_click() -> void:
	var mouse_pos = get_global_mouse_position()
	var world_pos = camera.get_canvas_transform().affine_inverse() * mouse_pos
	var clicked = hex_grid.get_hex_by_pixel(world_pos)

	if clicked.is_empty() or not player_ship:
		return

	var axial = clicked.axial
	var obstacles = []
	for entry in hex_grid.hex_map.values():
		if entry.occupied != null and entry.occupied != player_ship:
			obstacles.append(entry.axial)
		elif entry.blocked:
			obstacles.append(entry.axial)

	highlighter.clear_highlights()

	if axial == player_ship.grid_pos:
		selected_hex = Vector2.ZERO
		return

	if selected_hex == Vector2.ZERO:
		selected_hex = player_ship.grid_pos
		highlighter.highlight_cells([axial], Color(1, 1, 0, 0.4), 2)
		highlighter.highlight_reachable(player_ship.grid_pos, player_ship.action_points, obstacles)
	else:
		var path = highlighter.highlight_path(selected_hex, axial, obstacles)
		if not path.is_empty():
			player_ship.move_to(axial, path)
			selected_hex = player_ship.grid_pos
			highlighter.highlight_cells([axial], Color(0, 1, 0, 0.4), 2)
		else:
			selected_hex = Vector2.ZERO
