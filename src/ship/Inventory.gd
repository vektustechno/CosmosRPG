class_name Inventory
extends Resource

@export var items: Array = []
@export var max_items: int = 50
@export var credits: int = 1000
@export var resources: Dictionary = {}

func add_item(item: EquipmentData) -> bool:
	if items.size() >= max_items:
		return false
	items.append(item)
	return true

func remove_item(index: int) -> EquipmentData:
	if index < 0 or index >= items.size():
		return null
	var item = items[index]
	items.remove_at(index)
	return item

func get_item(index: int) -> EquipmentData:
	if index < 0 or index >= items.size():
		return null
	return items[index]

func has_item_ref(item: EquipmentData) -> bool:
	return items.has(item)

func remove_item_by_ref(item: EquipmentData) -> bool:
	var idx = items.find(item)
	if idx < 0:
		return false
	items.remove_at(idx)
	return true

func get_items_by_type(type: String) -> Array:
	var result = []
	for item in items:
		if item is EquipmentData and item.item_type == type:
			result.append(item)
	return result

func add_credits(amount: int) -> void:
	credits = maxi(0, credits + amount)

func spend_credits(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	return true

func add_resource(resource_id: String, amount: int) -> void:
	resources[resource_id] = resources.get(resource_id, 0) + amount

func has_resource(resource_id: String, amount: int) -> bool:
	return resources.get(resource_id, 0) >= amount

func spend_resource(resource_id: String, amount: int) -> bool:
	if not has_resource(resource_id, amount):
		return false
	resources[resource_id] -= amount
	return true
