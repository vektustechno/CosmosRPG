class_name StoryLoader
extends RefCounted

static func load_all(mission_manager: MissionManager) -> void:
	var file = FileAccess.open("res://src/data/story_missions.json", FileAccess.READ)
	if not file:
		push_error("StoryLoader: Could not open story_missions.json")
		return
	
	var text = file.get_as_text()
	var data = JSON.parse_string(text)
	if not data:
		return
	
	if data.has("prologue"):
		for entry in data["prologue"]:
			var mission = _create_mission(entry)
			if mission:
				mission_manager.register_mission(mission)
	
	if data.has("main_story"):
		for entry in data["main_story"]:
			var mission = _create_mission(entry)
			if mission:
				mission_manager.register_mission(mission)
	
	if data.has("final_act"):
		for entry in data["final_act"]:
			var mission = _create_mission(entry)
			if mission:
				mission_manager.register_mission(mission)

static func _create_mission(entry: Dictionary) -> MissionData:
	var mission = MissionData.new()
	mission.mission_id = entry.get("mission_id", "")
	mission.title = entry.get("title", "")
	mission.description = entry.get("description", "")
	mission.mission_type = entry.get("mission_type", "main")
	mission.starting_dialog = entry.get("starting_dialog", "")
	mission.completion_dialog = entry.get("completion_dialog", "")
	mission.prerequisites = entry.get("prerequisites", [])
	mission.next_missions = entry.get("next_missions", [])
	mission.rewards = entry.get("rewards", {})
	
	for obj_entry in entry.get("objectives", []):
		var obj = ObjectiveData.new()
		obj.objective_id = obj_entry.get("objective_id", "")
		obj.description = obj_entry.get("description", "")
		obj.objective_type = obj_entry.get("objective_type", "go_to")
		obj.target = obj_entry.get("target", "")
		obj.amount = obj_entry.get("amount", 1)
		mission.objectives.append(obj)
	
	return mission
