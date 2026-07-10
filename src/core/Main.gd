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

var selected_hex: Vector2 = Vector2.ZERO

func _ready() -> void:
	title_label.hide()
	Global.hex_grid = hex_grid

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

	if clicked.is_empty():
		return

	var axial = clicked.axial
	if selected_hex == Vector2.ZERO:
		selected_hex = axial
		highlighter.highlight_cells([axial], Color(1, 1, 0, 0.4))
		highlighter.highlight_reachable(axial, 5, [])
	else:
		var obstacles = []
		highlighter.clear_highlights()
		var path = highlighter.highlight_path(selected_hex, axial, obstacles)
		if path.is_empty():
			selected_hex = axial
			highlighter.highlight_cells([axial], Color(1, 1, 0, 0.4))
			highlighter.highlight_reachable(axial, 5, [])
