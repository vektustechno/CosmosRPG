extends RefCounted

static func calculate_damage(attack: Dictionary, defender: Ship, hit_arc: String) -> Dictionary:
	var weapon_damage = attack.get("damage", 10)
	var damage_type = attack.get("damage_type", "energy")
	var armor_bonus = attack.get("armor_pen", 0.0)
	
	var shield_remaining = defender.current_shields.get(hit_arc, 0)
	var hull_damage = weapon_damage
	var shield_damage = 0
	var status_applied = null
	
	match damage_type:
		"true":
			hull_damage = weapon_damage
		"energy":
			if shield_remaining > 0:
				shield_damage = mini(shield_remaining, weapon_damage * 2)
				hull_damage = maxi(0, weapon_damage - shield_damage / 2)
			hull_damage = int(hull_damage * 0.5)
		"kinetic":
			if shield_remaining > 0:
				shield_damage = mini(shield_remaining, int(weapon_damage * 0.5))
				hull_damage = maxi(0, weapon_damage - shield_damage * 2)
		"explosive":
			if shield_remaining > 0:
				shield_damage = mini(shield_remaining, weapon_damage)
				hull_damage = maxi(1, weapon_damage - shield_damage)
			hull_damage = int(hull_damage * 0.75)
		"ion":
			hull_damage = 0
			if randf() < 0.4:
				status_applied = {"type": "system_disabled", "duration": 2}
		"emp":
			shield_damage = shield_remaining
			hull_damage = 0
			status_applied = {"type": "emp", "duration": 1}
	
	defender.current_shields[hit_arc] = maxi(0, shield_remaining - shield_damage)
	defender.current_hp = maxi(0, defender.current_hp - hull_damage)
	
	var is_crit = randf() < (attack.get("crit_bonus", 0.0) + 0.1)
	var system_hit = ""
	if is_crit:
		system_hit = _apply_critical_hit(defender)
	
	if status_applied:
		defender.status_effects[status_applied.type] = status_applied.duration
	
	return {
		"shield_damage": shield_damage,
		"hull_damage": hull_damage,
		"crit": is_crit,
		"system_hit": system_hit,
		"destroyed": defender.current_hp <= 0,
		"status": status_applied
	}

static func get_arc_between(from_axial: Vector2, from_facing: int, to_axial: Vector2) -> String:
	var from_pixel = HexCoord.axial_to_pixel(from_axial.x, from_axial.y)
	var to_pixel = HexCoord.axial_to_pixel(to_axial.x, to_axial.y)
	var angle = rad_to_deg((to_pixel - from_pixel).angle())
	var facing_angle = -from_facing * 60.0
	var diff = fmod(fmod(angle - facing_angle + 540.0, 360.0) + 360.0, 360.0)
	
	if diff < 45.0 or diff > 315.0: return "front"
	elif diff >= 45.0 and diff < 135.0: return "right"
	elif diff >= 135.0 and diff < 225.0: return "rear"
	else: return "left"

static func _apply_critical_hit(defender: Ship) -> String:
	var systems = ["engine", "weapon", "reactor", "shield_gen", "bridge", "cargo"]
	var hit = systems[randi() % systems.size()]
	defender.status_effects[hit + "_hit"] = 2
	return hit
