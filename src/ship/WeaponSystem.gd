class_name WeaponSystem
extends Node

@export var ship: Ship

func _ready() -> void:
	if not ship:
		ship = get_parent() as Ship

func get_weapons_in_arc(target_pos: Vector2) -> Array:
	var available = []
	for mount in ship.weapon_mounts:
		if mount is WeaponMount and mount.weapon != null:
			if mount.can_shoot_at(ship.grid_pos, ship.facing, target_pos):
				var dist = HexCoord.hex_distance(ship.grid_pos, target_pos)
				if dist <= mount.weapon.range and dist >= 1:
					available.append(mount)
	return available

func fire_weapon(mount_index: int, target: Ship) -> bool:
	if mount_index < 0 or mount_index >= ship.weapon_mounts.size():
		return false
	
	var mount = ship.weapon_mounts[mount_index] as WeaponMount
	if not mount or not mount.weapon:
		return false
	
	var weapon = mount.weapon
	if ship.action_points < weapon.ap_cost:
		return false
	
	if not mount.can_shoot_at(ship.grid_pos, ship.facing, target.grid_pos):
		return false
	
	var dist = HexCoord.hex_distance(ship.grid_pos, target.grid_pos)
	if dist > weapon.range or dist < 1:
		return false
	
	ship.action_points -= weapon.ap_cost
	
	var proj_scene = preload("res://src/combat/Projectile.tscn")
	var proj = proj_scene.instantiate()
	proj.setup(ship, target, weapon)
	get_tree().current_scene.add_child(proj)
	
	return true

func get_all_fireable_weapons(target_pos: Vector2) -> Array:
	var result = []
	for i in range(ship.weapon_mounts.size()):
		var mount = ship.weapon_mounts[i] as WeaponMount
		if mount and mount.weapon:
			if mount.can_shoot_at(ship.grid_pos, ship.facing, target_pos):
				var dist = HexCoord.hex_distance(ship.grid_pos, target_pos)
				if dist <= mount.weapon.range and dist >= 1:
					if ship.action_points >= mount.weapon.ap_cost:
						result.append({"index": i, "mount": mount, "weapon": mount.weapon})
	return result
