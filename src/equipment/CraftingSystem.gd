extends RefCounted

static func craft(recipe_id: String, player_credits: int, player_resources: Dictionary) -> Dictionary:
	var recipes = _load_recipes()
	var recipe = recipes.get(recipe_id)
	if not recipe:
		return {"success": false, "reason": "Recipe not found"}
	
	var ingredients = recipe.get("ingredients", {})
	var cost = recipe.get("cost", 0)
	
	if player_credits < cost:
		return {"success": false, "reason": "Not enough credits"}
	
	for key in ingredients.keys():
		if player_resources.get(key, 0) < ingredients[key]:
			return {"success": false, "reason": "Missing: " + key}
	
	var result_type = recipe.get("result_type", "")
	var result_rarity = recipe.get("result_rarity", "common")
	var result_level = recipe.get("result_level", 1)
	
	var item = ItemGenerator.generate_item(result_type, result_rarity, result_level)
	if not item:
		return {"success": false, "reason": "Failed to generate item"}
	
	return {"success": true, "item": item}

static func _load_recipes() -> Dictionary:
	var file = FileAccess.open("res://src/data/recipes.json", FileAccess.READ)
	if not file:
		return {}
	return JSON.parse_string(file.get_as_text()) or {}
