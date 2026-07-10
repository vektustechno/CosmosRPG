class_name MissionData
extends Resource

@export var mission_id: String = ""
@export var title: String = ""
@export var description: String = ""
@export var mission_type: String = "main"
@export var objectives: Array = []
@export var rewards: Dictionary = {}
@export var prerequisites: Array = []
@export var next_missions: Array = []
@export var starting_dialog: String = ""
@export var completion_dialog: String = ""

var completed: bool = false
var active: bool = false

func is_prerequisites_met(completed_missions: Array) -> bool:
	for prereq in prerequisites:
		if not completed_missions.has(prereq):
			return false
	return true

func get_completion_pct() -> float:
	if objectives.is_empty():
		return 0.0
	var done = 0
	for obj in objectives:
		if obj is ObjectiveData and obj.is_complete():
			done += 1
	return float(done) / float(objectives.size())

func is_all_objectives_complete() -> bool:
	for obj in objectives:
		if obj is ObjectiveData and not obj.optional:
			if not obj.is_complete():
				return false
	return true
