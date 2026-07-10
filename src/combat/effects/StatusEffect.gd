class_name StatusEffect
extends Resource

@export var effect_id: String = ""
@export var effect_name: String = ""
@export var effect_type: String = "burn"
@export var duration: int = 3
@export var damage_per_turn: int = 0
@export var stat_modifier: Dictionary = {}
@export var icon_color: Color = Color(1, 0.5, 0)
