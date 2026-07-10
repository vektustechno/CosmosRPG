extends RefCounted

signal scan_completed(result: Dictionary)

static func can_scan(ship: Ship, object_pos: Vector2, scan_range: int) -> bool:
	var dist = HexCoord.hex_distance(ship.grid_pos, object_pos)
	return dist <= scan_range

static func perform_scan(ship: Ship, system: StarSystem, object_pos: Vector2) -> Dictionary:
	if not can_scan(ship, object_pos, _get_scan_range(ship)):
		return {"success": false, "reason": "Out of range"}
	
	var obj = system.get_object_at(object_pos)
	if obj.is_empty():
		return {"success": false, "reason": "Nothing to scan"}
	
	var scan_power = _get_scan_power(ship)
	var result = system.scan_object(system.system_objects.find(obj), scan_power)
	
	if ship.action_points > 0:
		ship.action_points -= 1
	
	return result

static func _get_scan_range(ship: Ship) -> int:
	var base_range = 4
	var stats = ship.stats
	base_range += stats.get("scan_range_bonus", 0)
	
	for child in ship.get_children():
		if child is WeaponSystem:
			for mount in ship.weapon_mounts:
				if mount is WeaponMount and mount.weapon:
					pass
	
	return base_range

static func _get_scan_power(ship: Ship) -> int:
	var base_power = 5
	base_power += ship.stats.get("scan_range_bonus", 0) * 2
	return base_power

static func get_scan_range_indicator(ship: Ship) -> int:
	return _get_scan_range(ship)
