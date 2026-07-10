extends RefCounted

static func generate_inventory(station: StationData, player_level: int) -> Array:
	var items = []
	var faction_system = _get_faction_system()
	if faction_system:
		items = faction_system.get_available_items(station.faction_id)
	
	var count = randi() % 4 + 3
	for i in range(count):
		var lvl = maxi(1, player_level + randi() % 5 - 2)
		var item = ItemGenerator.generate_random_drop(lvl, 0.3)
		if item:
			if item.set_id == "":
				items.append(item)
	
	return items

static func buy_item(item: EquipmentData, player_inventory: Inventory, player_credits: int) -> Dictionary:
	var price = calculate_price(item)
	if player_credits < price:
		return {"success": false, "reason": "Not enough credits"}
	
	var added = player_inventory.add_item(item)
	if not added:
		return {"success": false, "reason": "Inventory full"}
	
	return {"success": true, "price": price}

static func sell_item(item_index: int, player_inventory: Inventory) -> Dictionary:
	var item = player_inventory.get_item(item_index)
	if not item:
		return {"success": false, "reason": "Item not found"}
	
	var price = int(calculate_price(item) * 0.5)
	player_inventory.remove_item(item_index)
	player_inventory.add_credits(price)
	return {"success": true, "price": price}

static func calculate_price(item: EquipmentData) -> int:
	var rarity_mult = [0.3, 1.0, 2.0, 5.0, 12.0, 30.0, 75.0, 200.0]
	var tier = item.get_rarity_tier() - 1
	var mult = rarity_mult[clampi(tier, 0, rarity_mult.size() - 1)]
	var base = 100.0 + item.level * 50.0
	for a in item.affixes:
		if a is AffixData:
			base += a.tier * 100.0
	return int(base * mult)

static func _get_faction_system() -> FactionSystem:
	var root = Engine.get_main_loop().root
	for child in root.get_children():
		if child is FactionSystem:
			return child
	return null
