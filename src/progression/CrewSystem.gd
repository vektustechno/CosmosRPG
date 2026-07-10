extends Node

var crew: Array = []
var max_crew: int = 5

signal crew_changed

func add_member(member: CrewMember) -> bool:
	if crew.size() >= max_crew:
		return false
	crew.append(member)
	crew_changed.emit()
	return true

func remove_member(index: int) -> bool:
	if index < 0 or index >= crew.size():
		return false
	crew.remove_at(index)
	crew_changed.emit()
	return true

func assign_to_station(member_index: int, station: String) -> bool:
	if member_index < 0 or member_index >= crew.size():
		return false
	crew[member_index].assigned_station = station
	crew_changed.emit()
	return true

func get_active_bonuses() -> Dictionary:
	var bonuses = {}
	for member in crew:
		if member is CrewMember:
			for key in member.passive_bonus.keys():
				var val = member.passive_bonus[key]
				if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
					bonuses[key] = bonuses.get(key, 0) + val
				else:
					bonuses[key] = val
	
	var synergies = get_synergies()
	for bonus in synergies:
		for key in bonus.keys():
			var val = bonus[key]
			if typeof(val) == TYPE_INT or typeof(val) == TYPE_FLOAT:
				bonuses[key] = bonuses.get(key, 0) + val
			else:
				bonuses[key] = val
	
	return bonuses

func get_synergies() -> Array:
	var result = []
	var roles = []
	for m in crew:
		if m is CrewMember:
			roles.append(m.role)
	
	if roles.has("engineer") and roles.has("scientist"):
		result.append({"shield_recharge": 20, "description": "Engineer + Scientist: +20% shield recharge"})
	if roles.has("captain") and roles.has("combat_officer"):
		result.append({"weapon_damage": 10, "description": "Captain + Combat Officer: +10% weapon damage"})
	if roles.has("navigator") and roles.has("engineer"):
		result.append({"speed_bonus": 1, "description": "Navigator + Engineer: +1 speed"})
	if roles.size() >= 4:
		result.append({"all_stats": 5, "description": "4+ crew members: +5% all stats"})
	
	return result
