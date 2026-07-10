class_name Tactic
extends Resource

@export var tactic_id: String = ""
@export var priority: int = 5

func evaluate(ship: Ship, allies: Array, enemies: Array) -> bool:
	return false

func execute(ship: Ship, target: Ship) -> Dictionary:
	return {"action": "none", "target": null, "weapon_index": -1}

static func create_flank() -> Tactic:
	var t = Tactic.new()
	t.tactic_id = "flank"
	t.priority = 8
	return t

static func create_focus_fire() -> Tactic:
	var t = Tactic.new()
	t.tactic_id = "focus_fire"
	t.priority = 7
	return t

static func create_kite() -> Tactic:
	var t = Tactic.new()
	t.tactic_id = "kite"
	t.priority = 6
	return t

static func create_shield_balance() -> Tactic:
	var t = Tactic.new()
	t.tactic_id = "shield_balance"
	t.priority = 5
	return t

static func create_emergency_repair() -> Tactic:
	var t = Tactic.new()
	t.tactic_id = "emergency_repair"
	t.priority = 9
	return t

static func create_power_surge() -> Tactic:
	var t = Tactic.new()
	t.tactic_id = "power_surge"
	t.priority = 3
	return t

static func create_fall_back() -> Tactic:
	var t = Tactic.new()
	t.tactic_id = "fall_back"
	t.priority = 10
	return t

static func create_overwatch() -> Tactic:
	var t = Tactic.new()
	t.tactic_id = "overwatch"
	t.priority = 4
	return t
