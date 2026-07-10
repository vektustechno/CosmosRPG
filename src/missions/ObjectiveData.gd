class_name ObjectiveData
extends Resource

@export var objective_id: String = ""
@export var description: String = ""
@export var objective_type: String = "go_to"
@export var target: String = ""
@export var amount: int = 1
@export var current_progress: int = 0
@export var optional: bool = false

func is_complete() -> bool:
	return current_progress >= amount

func advance(progress: int = 1) -> void:
	current_progress += progress
