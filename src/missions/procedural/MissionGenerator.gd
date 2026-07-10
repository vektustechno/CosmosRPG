extends RefCounted

static func generate_side_mission(sector_level: int, faction_id: String = "") -> MissionData:
	var templates = [
		_clear_enemies_template,
		_escort_template,
		_gather_resources_template,
		_explore_template,
		_hunt_boss_template,
		_delivery_template
	]
	
	var chosen = templates[randi() % templates.size()]
	var mission = chosen.call(sector_level, faction_id)
	
	mission.mission_id = "proc_%d_%d" % [sector_level, randi() % 99999]
	mission.mission_type = "side"
	
	return mission

static func _clear_enemies_template(level: int, faction: String) -> MissionData:
	var m = MissionData.new()
	m.title = "Clear the Area"
	m.description = "Eliminate all hostiles in the target sector."
	m.rewards = {"xp": level * 50, "credits": level * 100}
	if faction != "":
		m.rewards["reputation"] = {faction: 20}
	
	var obj = ObjectiveData.new()
	obj.objective_id = "kill_%d" % level
	obj.objective_type = "destroy"
	obj.description = "Destroy enemy ships: %d" % (level / 10 + 2)
	obj.amount = level / 10 + 2
	m.objectives.append(obj)
	
	return m

static func _escort_template(level: int, faction: String) -> MissionData:
	var m = MissionData.new()
	m.title = "Escort Convoy"
	m.description = "Protect a civilian convoy through hostile space."
	m.rewards = {"xp": level * 60, "credits": level * 120}
	if faction != "":
		m.rewards["reputation"] = {faction: 25}
	
	var obj = ObjectiveData.new()
	obj.objective_id = "escort_%d" % level
	obj.objective_type = "escort"
	obj.description = "Survive %d enemy waves" % (level / 15 + 2)
	obj.amount = level / 15 + 2
	m.objectives.append(obj)
	
	return m

static func _gather_resources_template(level: int, faction: String) -> MissionData:
	var m = MissionData.new()
	m.title = "Resource Collection"
	m.description = "Gather valuable resources from asteroid fields."
	m.rewards = {"xp": level * 40, "credits": level * 80}
	if faction != "":
		m.rewards["reputation"] = {faction: 15}
	
	var obj = ObjectiveData.new()
	obj.objective_id = "gather_%d" % level
	obj.objective_type = "gather"
	obj.description = "Gather %d units of resources" % (level * 3)
	obj.amount = level * 3
	m.objectives.append(obj)
	
	return m

static func _explore_template(level: int, faction: String) -> MissionData:
	var m = MissionData.new()
	m.title = "Exploration Mission"
	m.description = "Scan and catalogue all objects in an uncharted system."
	m.rewards = {"xp": level * 55, "credits": level * 90, "resources": {"datashards": level / 5 + 1}}
	if faction != "":
		m.rewards["reputation"] = {faction: 30}
	
	var obj = ObjectiveData.new()
	obj.objective_id = "explore_%d" % level
	obj.objective_type = "explore"
	obj.description = "Scan %d objects" % (level / 10 + 3)
	obj.amount = level / 10 + 3
	m.objectives.append(obj)
	
	return m

static func _hunt_boss_template(level: int, faction: String) -> MissionData:
	var m = MissionData.new()
	m.title = "Bounty Hunt"
	m.description = "A dangerous target is hiding in the area. Eliminate them."
	m.rewards = {"xp": level * 100, "credits": level * 250}
	if faction != "":
		m.rewards["reputation"] = {faction: 50}
	
	var obj = ObjectiveData.new()
	obj.objective_id = "hunt_%d" % level
	obj.objective_type = "destroy"
	obj.description = "Destroy the bounty target"
	obj.amount = 1
	m.objectives.append(obj)
	
	return m

static func _delivery_template(level: int, faction: String) -> MissionData:
	var m = MissionData.new()
	m.title = "Supply Delivery"
	m.description = "Deliver critical supplies to an outpost."
	m.rewards = {"xp": level * 30, "credits": level * 150}
	if faction != "":
		m.rewards["reputation"] = {faction: 15}
	
	var obj = ObjectiveData.new()
	obj.objective_id = "deliver_%d" % level
	obj.objective_type = "go_to"
	obj.description = "Reach the delivery point"
	obj.amount = 1
	m.objectives.append(obj)
	
	return m
