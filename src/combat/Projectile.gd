class_name Projectile
extends Area2D

var target_ship: Ship
var speed: float = 200.0
var damage: int = 10
var damage_type: String = "energy"
var from_direction: String = "front"
var weapon_data: WeaponData
var shooter: Ship

func _ready() -> void:
	body_entered.connect(_on_hit)

func _process(delta: float) -> void:
	if not target_ship or not is_instance_valid(target_ship):
		queue_free()
		return
	
	var target_pos = target_ship.position
	var dir = (target_pos - position).normalized()
	position += dir * speed * delta
	
	if position.distance_to(target_pos) < 8:
		_hit_target()

func _hit_target() -> void:
	if not target_ship or not is_instance_valid(target_ship):
		queue_free()
		return
	
	var hit_roll = randf()
	if hit_roll > weapon_data.accuracy:
		queue_free()
		return
	
	var result = target_ship.take_damage(weapon_data.damage, damage_type, from_direction)
	
	if weapon_data.status_effect and not result.get("destroyed", false):
		if randf() < weapon_data.status_effect.get("chance", 1.0):
			target_ship.status_effects[weapon_data.status_effect.get("type", "burn")] = weapon_data.status_effect.get("duration", 3)
	
	if shooter and shooter.is_player:
		print("Hit %s for %d hull damage (%s)" % [target_ship.ship_class_id, result.get("hull_damage", 0), "CRIT!" if result.get("crit") else "hit"])
	
	queue_free()

func _on_hit(_body: Node2D) -> void:
	_hit_target()

func setup(from: Ship, to: Ship, weapon: WeaponData) -> void:
	shooter = from
	target_ship = to
	weapon_data = weapon
	damage = weapon.damage
	damage_type = weapon.damage_type
	speed = 150.0 + weapon.damage * 2
	
	var to_pixel = HexCoord.axial_to_pixel(to.grid_pos.x, to.grid_pos.y)
	var from_pixel = HexCoord.axial_to_pixel(from.grid_pos.x, from.grid_pos.y)
	var dir_vec = (to_pixel - from_pixel).normalized()
	
	from_direction = _get_arc_between(from.grid_pos, from.facing, to.grid_pos)
	
	position = from_pixel
	rotation = dir_vec.angle()

func _get_arc_between(from_axial: Vector2, from_facing: int, to_axial: Vector2) -> String:
	var from_pixel = HexCoord.axial_to_pixel(from_axial.x, from_axial.y)
	var to_pixel = HexCoord.axial_to_pixel(to_axial.x, to_axial.y)
	var angle = rad_to_deg((to_pixel - from_pixel).angle())
	var facing_angle = -from_facing * 60.0
	var diff = fmod(fmod(angle - facing_angle + 540.0, 360.0) + 360.0, 360.0)
	
	if diff < 45.0 or diff > 315.0:
		return "front"
	elif diff >= 45.0 and diff < 135.0:
		return "right"
	elif diff >= 135.0 and diff < 225.0:
		return "rear"
	else:
		return "left"
