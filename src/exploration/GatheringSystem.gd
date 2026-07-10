extends RefCounted

static func can_gather(ship: Ship, object: Dictionary) -> bool:
	if object.get("type") not in ["asteroid_field", "planet"]:
		return false
	var resources = object.get("resources", {})
	return not resources.is_empty()

static func gather(ship: Ship, object: Dictionary) -> Dictionary:
	if not can_gather(ship, object):
		return {"success": false, "reason": "Cannot gather from this object"}
	
	var resources = object.get("resources", {})
	if resources.is_empty():
		return {"success": false, "reason": "Depleted"}
	
	var gathered = {}
	var yield_bonus = 1.0 + ship.stats.get("resource_yield", 0.0)
	
	for res_id in resources.keys():
		var amount = resources[res_id]
		var gathered_amount = maxi(1, int(amount * 0.3 * yield_bonus))
		gathered[res_id] = gathered_amount
		resources[res_id] = amount - gathered_amount
	
	if ship.action_points > 0:
		ship.action_points -= 1
	
	for res_id in gathered.keys():
		ship.inventory.add_resource(res_id, gathered[res_id])
	
	return {"success": true, "gathered": gathered}

static func mine_asteroid(ship: Ship, system: StarSystem, object_pos: Vector2) -> Dictionary:
	var obj = system.get_object_at(object_pos)
	if obj.is_empty():
		return {"success": false, "reason": "Nothing there"}
	
	return gather(ship, obj)

static func land_on_planet(ship: Ship, system: StarSystem, object_pos: Vector2) -> Dictionary:
	var obj = system.get_object_at(object_pos)
	if obj.is_empty():
		return {"success": false, "reason": "Nothing there"}
	if obj.get("type") != "planet":
		return {"success": false, "reason": "Not a planet"}
	
	var actions = ["gather_resources", "search_artifacts", "scan_terrain", "establish_outpost"]
	var chosen = actions[randi() % actions.size()]
	
	var result = {"success": true, "action": chosen, "description": ""}
	
	match chosen:
		"gather_resources":
			var g = gather(ship, obj)
			result["description"] = "Collected surface samples"
			result["gathered"] = g.get("gathered", {})
		"search_artifacts":
			if randf() < 0.3:
				var item = ItemGenerator.generate_random_drop(ship.stats.get("level", 1), 0.8)
				if item:
					ship.inventory.add_item(item)
					result["description"] = "Found " + item.get_display_name()
			else:
				result["description"] = "Nothing of interest found"
		"scan_terrain":
			var scan_range = ScanSystem.get_scan_range_indicator(ship)
			result["description"] = "Terrain scanned. Resources detected."
		"establish_outpost":
			result["description"] = "Outpost established. Resources will be auto-collected."
	
	return result
