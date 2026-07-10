extends Control

@onready var game_world: Node2D = $GameWorld
@onready var hex_grid: Node2D = $GameWorld/HexGrid
@onready var camera: Camera2D = $GameWorld/Camera2D
@onready var title_label: Label = $UILayer/TitleLabel

var dragging: bool = false
var drag_start: Vector2
var camera_start: Vector2
var zoom_level: float = 1.0

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

	if event is InputEventMouseMotion and dragging:
		var delta = get_global_mouse_position() - drag_start
		camera.position = camera_start - delta * camera.zoom.x
