extends Node

signal mission_started(mission: MissionData)
signal objective_completed(mission_id: String, objective_id: String)
signal mission_completed(mission_id: String)
signal mission_failed(mission_id: String)

var active_missions: Array = []
var completed_missions: Array = []
var all_missions: Dictionary = {}

func _ready() -> void:
	_register_missions()

func _register_missions() -> void:
	pass

func register_mission(mission: MissionData) -> void:
	all_missions[mission.mission_id] = mission

func start_mission(mission_id: String) -> bool:
	var mission = all_missions.get(mission_id)
	if not mission:
		return false
	if mission.completed or mission.active:
		return false
	
	mission.active = true
	active_missions.append(mission)
	mission_started.emit(mission)
	return true

func complete_objective(objective_id: String) -> bool:
	for mission in active_missions:
		if not (mission is MissionData):
			continue
		for obj in mission.objectives:
			if obj is ObjectiveData and obj.objective_id == objective_id:
				obj.advance()
				objective_completed.emit(mission.mission_id, objective_id)
				if mission.is_all_objectives_complete():
					_complete_mission(mission)
				return true
	return false

func fail_mission(mission_id: String) -> bool:
	for i in range(active_missions.size()):
		var mission = active_missions[i]
		if mission is MissionData and mission.mission_id == mission_id:
			active_missions.remove_at(i)
			mission_failed.emit(mission_id)
			return true
	return false

func _complete_mission(mission: MissionData) -> void:
	mission.completed = true
	mission.active = false
	completed_missions.append(mission.mission_id)
	active_missions.erase(mission)
	
	if mission.rewards.has("xp"):
		var lvl_sys = _get_level_system()
		if lvl_sys:
			lvl_sys.add_xp(mission.rewards["xp"])
	
	if mission.rewards.has("credits"):
		var player_ship = Global.player_ship
		if player_ship:
			player_ship.inventory.add_credits(mission.rewards["credits"])
	
	if mission.rewards.has("reputation"):
		var faction_sys = _get_faction_system()
		if faction_sys:
			for fid in mission.rewards["reputation"].keys():
				faction_sys.change_reputation(fid, mission.rewards["reputation"][fid])
	
	for next_id in mission.next_missions:
		var next = all_missions.get(next_id)
		if next and next.is_prerequisites_met(completed_missions):
			start_mission(next_id)
	
	mission_completed.emit(mission.mission_id)

func get_active_mission(mission_id: String) -> MissionData:
	for m in active_missions:
		if m is MissionData and m.mission_id == mission_id:
			return m
	return null

func _get_level_system() -> LevelSystem:
	var root = Engine.get_main_loop().root
	for child in root.get_children():
		if child is LevelSystem:
			return child
	return null

func _get_faction_system() -> FactionSystem:
	var root = Engine.get_main_loop().root
	for child in root.get_children():
		if child is FactionSystem:
			return child
	return null
