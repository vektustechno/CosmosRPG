extends Node

var trees: Dictionary = {}
var unlocked_nodes: Dictionary = {}

func _ready() -> void:
	_load_trees()

func _load_trees() -> void:
	var file = FileAccess.open("res://src/data/skill_tree.json", FileAccess.READ)
	if not file:
		return
	trees = JSON.parse_string(file.get_as_text()) or {}

func get_tree_names() -> Array:
	return trees.keys()

func get_nodes(tree_name: String) -> Array:
	var tree = trees.get(tree_name, {})
	return tree.get("nodes", [])

func is_unlocked(node_id: String) -> bool:
	return unlocked_nodes.get(node_id, false)

func can_unlock(node_id: String, available_points: int) -> bool:
	if is_unlocked(node_id):
		return false
	var node_data = _find_node(node_id)
	if not node_data:
		return false
	if node_data.get("cost", 1) > available_points:
		return false
	for req in node_data.get("requires", []):
		if not is_unlocked(req):
			return false
	return true

func unlock(node_id: String) -> bool:
	if not can_unlock(node_id, 99):
		return false
	unlocked_nodes[node_id] = true
	return true

func get_active_effects() -> Dictionary:
	var effects = {}
	for node_id in unlocked_nodes.keys():
		var node_data = _find_node(node_id)
		if node_data:
			var eff = node_data.get("effect", {})
			for key in eff.keys():
				if typeof(eff[key]) == TYPE_BOOL:
					effects[key] = true
				elif typeof(eff[key]) == TYPE_INT or typeof(eff[key]) == TYPE_FLOAT:
					effects[key] = effects.get(key, 0) + eff[key]
	return effects

func get_unlocked_count() -> int:
	return unlocked_nodes.size()

func get_total_node_count() -> int:
	var count = 0
	for t in trees.keys():
		count += len(trees[t].get("nodes", []))
	return count

func _find_node(node_id: String) -> Dictionary:
	for t in trees.keys():
		for node in trees[t].get("nodes", []):
			if node.get("id", "") == node_id:
				return node
	return {}
