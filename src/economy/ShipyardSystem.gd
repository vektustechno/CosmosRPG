extends RefCounted

static func get_available_ships(station_faction: String, player_level: int, player_reputation: Dictionary) -> Array:
	var all_classes = ShipClassData.load_all()
	var available = []
	
	for cid in all_classes.keys():
		var cls = all_classes[cid]
		if cls.price == 0:
			continue
		if cls.sector_unlock > (player_level / 10) + 1:
			continue
		
		var rep_ok = true
		for rep_id in cls.required_reputation.keys():
			var needed = cls.required_reputation[rep_id]
			if player_reputation.get(rep_id, 0) < needed:
				rep_ok = false
				break
		
		if rep_ok:
			available.append(cls)
	
	return available

static func buy_ship(class_id: String, player_inventory: Inventory, current_ship: Ship) -> Dictionary:
	var all_classes = ShipClassData.load_all()
	var cls = all_classes.get(class_id)
	if not cls:
		return {"success": false, "reason": "Ship class not found"}
	
	if not player_inventory.spend_credits(cls.price):
		return {"success": false, "reason": "Not enough credits"}
	
	for slot in current_ship.equipped_items.keys():
		var items_in_slot = current_ship.equipped_items[slot]
		if items_in_slot is Array:
			for item in items_in_slot:
				if item is EquipmentData:
					player_inventory.add_item(item)
		elif items_in_slot is EquipmentData:
			player_inventory.add_item(items_in_slot)
	
	current_ship.change_ship(class_id)
	
	return {"success": true, "new_class": class_id}

static func sell_ship(class_id: String, player_inventory: Inventory, all_classes: Dictionary) -> Dictionary:
	var cls = all_classes.get(class_id)
	if not cls:
		return {"success": false, "reason": "Ship class not found"}
	
	var sell_price = int(cls.price * 0.5)
	player_inventory.add_credits(sell_price)
	return {"success": true, "price": sell_price}
