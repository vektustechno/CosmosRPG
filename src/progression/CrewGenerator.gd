extends RefCounted

static func generate_random_crew(level: int = 1, station_type: String = "") -> CrewMember:
	var first_names = ["Aria", "Kael", "Zara", "Nyx", "Orin", "Vex", "Lira", "Dorn", "Sera", "Jax"]
	var last_names = ["Hawkins", "Voss", "Chen", "Reyes", "Kor", "Sol", "Drake", "Finn", "Ash", "Vane"]
	
	var roles = ["captain", "navigator", "engineer", "scientist", "combat_officer"]
	if station_type != "" and station_type in roles:
		roles = [station_type]
	
	var member = CrewMember.new()
	member.crew_id = "crew_%d_%d" % [randi() % 9999, level]
	member.name = first_names[randi() % first_names.size()] + " " + last_names[randi() % last_names.size()]
	member.role = roles[randi() % roles.size()]
	member.level = level
	
	var skill_pool = _get_skills_for_role(member.role)
	for skill in skill_pool:
		member.skills[skill] = randi() % min(level, 10) + 1
	
	member.passive_bonus = _generate_passive(member.role, level)
	
	return member

static func _get_skills_for_role(role: String) -> Array:
	match role:
		"captain": return ["leadership", "tactics", "diplomacy"]
		"navigator": return ["piloting", "astrogation", "evasion"]
		"engineer": return ["repair", "power_management", "shield_ops"]
		"scientist": return ["scanning", "analysis", "xenology"]
		"combat_officer": return ["gunnery", "targeting", "critical_strike"]
	return ["general"]

static func _generate_passive(role: String, level: int) -> Dictionary:
	var bonus = level * 2
	match role:
		"captain": return {"crew_efficiency": bonus}
		"navigator": return {"speed_bonus": max(1, level / 5), "turn_rate_bonus": level * 3}
		"engineer": return {"shield_recharge": bonus, "repair_amount": bonus}
		"scientist": return {"scan_range_bonus": max(1, level / 3), "resource_yield": level * 0.02}
		"combat_officer": return {"weapon_damage": bonus, "crit_chance": level * 0.005}
	return {}
