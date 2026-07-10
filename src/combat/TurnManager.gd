class_name TurnManager
extends Node

signal turn_began(ship: Ship)
signal turn_ended(ship: Ship)
signal combat_over(result: String)

enum Phase { PRE_COMBAT, PLAYER_TURN, ENEMY_TURN, POST_COMBAT }

var participants: Array = []
var turn_order: Array = []
var current_index: int = 0
var phase: Phase = Phase.PRE_COMBAT
var is_combat_active: bool = false

func start_combat(ships: Array) -> void:
	participants = ships.duplicate()
	turn_order = []
	
	for ship in participants:
		if ship is Ship:
			turn_order.append(ship)
	
	current_index = 0
	is_combat_active = true
	phase = Phase.PLAYER_TURN
	_begin_turn()

func end_turn() -> void:
	if not is_combat_active:
		return
	
	var current_ship = _get_current_ship()
	if current_ship:
		turn_ended.emit(current_ship)
	
	current_index += 1
	
	if current_index >= turn_order.size():
		current_index = 0
	
	_begin_turn()

func _begin_turn() -> void:
	var ship = _get_current_ship()
	if not ship:
		end_combat("draw")
		return
	
	if ship.current_hp <= 0:
		turn_order.erase(ship)
		if turn_order.is_empty():
			end_combat("defeat")
			return
		end_turn()
		return
	
	phase = Phase.PLAYER_TURN if ship.is_player else Phase.ENEMY_TURN
	ship.new_turn()
	turn_began.emit(ship)

func _get_current_ship() -> Ship:
	if current_index < 0 or current_index >= turn_order.size():
		return null
	return turn_order[current_index] as Ship

func get_current_ship() -> Ship:
	return _get_current_ship()

func is_player_turn() -> bool:
	return phase == Phase.PLAYER_TURN

func end_combat(result: String) -> void:
	is_combat_active = false
	phase = Phase.POST_COMBAT
	combat_over.emit(result)

func add_participant(ship: Ship) -> void:
	if ship and not participants.has(ship):
		participants.append(ship)
		turn_order.append(ship)

func remove_participant(ship: Ship) -> void:
	participants.erase(ship)
	turn_order.erase(ship)
