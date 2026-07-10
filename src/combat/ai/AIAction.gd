class_name AIAction
extends RefCounted

enum Type { MOVE, ROTATE, FIRE, ACTIVATE_MODULE, WAIT, FLEE }

var action_type: Type = Type.WAIT
var target_pos: Vector2
var target_ship: Ship
var weapon_index: int = -1
var ap_cost: int = 0
