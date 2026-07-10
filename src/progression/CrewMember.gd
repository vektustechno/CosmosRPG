class_name CrewMember
extends Resource

@export var crew_id: String = ""
@export var name: String = "Unknown"
@export var role: String = "engineer"
@export var level: int = 1
@export var xp: int = 0
@export var skills: Dictionary = {}
@export var passive_bonus: Dictionary = {}
@export var assigned_station: String = ""

func get_role_name() -> String:
	var names = {
		"captain": "Captain",
		"navigator": "Navigator",
		"engineer": "Engineer",
		"scientist": "Scientist",
		"combat_officer": "Combat Officer"
	}
	return names.get(role, role)

func get_skill_level(skill_id: String) -> int:
	return skills.get(skill_id, 0)

func add_xp(amount: int) -> void:
	xp += amount
	var needed = level * 100
	while xp >= needed:
		xp -= needed
		level += 1
		needed = level * 100
