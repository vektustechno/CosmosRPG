extends Control

@onready var game_world: Node2D = $GameWorld
@onready var hex_grid: HexGrid = $GameWorld/HexGrid
@onready var camera: Camera2D = $GameWorld/Camera2D
@onready var highlighter: HexHighlighter = $GameWorld/HexHighlighter
@onready var ap_bar: Control = $UILayer/APBar
@onready var end_turn_btn: Button = $UILayer/EndTurnButton
@onready var mode_label: Label = $UILayer/ModeLabel
@onready var turn_label: Label = $UILayer/TurnLabel

var dragging: bool = false
var drag_start: Vector2
var camera_start: Vector2
var zoom_level: float = 1.0

var player_ship: Ship
var enemy_ships: Array = []
var selected_hex: Vector2 = Vector2.ZERO
var mode: String = "move"
var turn_manager: TurnManager

func _ready() -> void:
	Global.hex_grid = hex_grid
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	Global.turn_manager = turn_manager
	
	turn_manager.turn_began.connect(_on_turn_began)
	turn_manager.turn_ended.connect(_on_turn_ended)
	turn_manager.combat_over.connect(_on_combat_over)
	
	end_turn_btn.pressed.connect(_on_end_turn)
	
	_spawn_player_ship()
	_spawn_enemy_ships()
	_start_combat()

func _spawn_player_ship() -> void:
	var ship_scene = preload("res://src/ship/Ship.tscn")
	player_ship = ship_scene.instantiate()
	player_ship.is_player = true
	player_ship.ship_class_id = "shuttle"
	player_ship.grid_pos = Vector2(5, 5)
	game_world.add_child(player_ship)
	Global.player_ship = player_ship

func _spawn_enemy_ships() -> void:
	var ship_scene = preload("res://src/ship/Ship.tscn")
	var positions = [Vector2(12, 8), Vector2(10, 12)]
	for i in range(2):
		var enemy = ship_scene.instantiate()
		enemy.is_player = false
		enemy.ship_class_id = "fighter" if i == 0 else "shuttle"
		enemy.grid_pos = positions[i]
		game_world.add_child(enemy)
		enemy_ships.append(enemy)

func _start_combat() -> void:
	var all_ships = [player_ship] + enemy_ships
	turn_manager.start_combat(all_ships)

func _on_turn_began(ship: Ship) -> void:
	if ship.is_player:
		turn_label.text = "Your Turn"
		end_turn_btn.disabled = false
	else:
		turn_label.text = "Enemy Turn (%s)" % ship.ship_class_id
		end_turn_btn.disabled = true
		_call_enemy_ai(ship)
	_update_ap_bar()

func _on_turn_ended(_ship: Ship) -> void:
	pass

func _on_combat_over(result: String) -> void:
	turn_label.text = "Combat Over: " + result
	end_turn_btn.disabled = true

func _on_end_turn() -> void:
	if turn_manager.is_player_turn():
		turn_manager.end_turn()

func _call_enemy_ai(ship: Ship) -> void:
	var weapon_sys = _get_weapon_system(ship)
	if not weapon_sys:
		await get_tree().create_timer(0.5).timeout
		turn_manager.end_turn()
		return
	
	var target = player_ship
	var dist = HexCoord.hex_distance(ship.grid_pos, target.grid_pos)
	
	var mounts = weapon_sys.get_all_fireable_weapons(target.grid_pos)
	if not mounts.is_empty():
		var fired = weapon_sys.fire_weapon(mounts[0].index, target)
		await get_tree().create_timer(0.3).timeout
	
	if dist > 3:
		var obstacles = _get_obstacles()
		var reachable = Pathfinder.get_reachable(ship.grid_pos, ship.action_points, obstacles)
		var best_axial = ship.grid_pos
		var best_dist = dist
		for key in reachable.keys():
			var parts = key.split(",")
			var axial = Vector2(int(parts[0]), int(parts[1]))
			var d = HexCoord.hex_distance(axial, target.grid_pos)
			if d < best_dist and d > 2:
				best_dist = d
				best_axial = axial
		if best_axial != ship.grid_pos:
			var path = Pathfinder.find_path(ship.grid_pos, best_axial, obstacles)
			if not path.is_empty():
				ship.move_to(best_axial, path)
				await get_tree().create_timer(0.2).timeout
	
	await get_tree().create_timer(0.3).timeout
	turn_manager.end_turn()

func _get_weapon_system(ship: Ship) -> WeaponSystem:
	for child in ship.get_children():
		if child is WeaponSystem:
			return child
	return null

func _get_obstacles() -> Array:
	var obs = []
	for entry in hex_grid.hex_map.values():
		if entry.blocked:
			obs.append(entry.axial)
		if entry.occupied != null and entry.occupied != player_ship:
			for es in enemy_ships:
				if entry.occupied == es:
					obs.append(entry.axial)
	return obs

func _update_ap_bar() -> void:
	if not player_ship:
		return
	for child in ap_bar.get_children():
		child.queue_free()
	for i in range(player_ship.max_action_points):
		var dot = ColorRect.new()
		dot.size = Vector2(16, 16)
		dot.position = Vector2(i * 20, 0)
		dot.color = Color(0.3, 0.8, 0.3) if i < player_ship.action_points else Color(0.2, 0.2, 0.2)
		ap_bar.add_child(dot)

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
		elif event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
			_on_right_click()

	if event is InputEventMouseMotion and dragging:
		var delta = get_global_mouse_position() - drag_start
		camera.position = camera_start - delta * camera.zoom.x

func _on_right_click() -> void:
	mode = "attack" if mode == "move" else "move"
	mode_label.text = "Mode: " + mode

func _on_click() -> void:
	if not turn_manager.is_player_turn():
		return
	var mouse_pos = get_global_mouse_position()
	var world_pos = camera.get_canvas_transform().affine_inverse() * mouse_pos
	var clicked = hex_grid.get_hex_by_pixel(world_pos)
	if clicked.is_empty() or not player_ship:
		return
	var axial = clicked.axial
	if mode == "move":
		_handle_move_click(axial)
	else:
		_handle_attack_click(axial)

func _handle_move_click(axial: Vector2) -> void:
	var obstacles = _get_obstacles()
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
			_update_ap_bar()
		else:
			selected_hex = Vector2.ZERO
		highlighter.clear_highlights()

func _handle_attack_click(axial: Vector2) -> void:
	highlighter.clear_highlights()
	var weapon_sys = _get_weapon_system(player_ship)
	if not weapon_sys:
		return
	var mounts = weapon_sys.get_all_fireable_weapons(axial)
	if mounts.is_empty():
		return
	var target: Ship = null
	for es in enemy_ships:
		if es.grid_pos == axial and es.current_hp > 0:
			target = es
			break
	if target:
		var fired = weapon_sys.fire_weapon(mounts[0].index, target)
		if fired:
			_update_ap_bar()
			if target.current_hp <= 0:
				highlighter.highlight_cells([axial], Color(1, 0, 0, 0.5), 3)
