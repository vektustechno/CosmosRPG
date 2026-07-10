class_name WeaponMount
extends Resource

@export var mount_id: String = ""
@export var arc_type: String = "forward"
@export var arc_angle: float = 90.0
@export var weapon: WeaponData = null

func can_shoot_at(from_pos: Vector2, from_facing: int, target_pos: Vector2) -> bool:
	if weapon == null:
		return false
	
	var dist = HexCoord.hex_distance(from_pos, target_pos)
	if dist > weapon.range or dist < 1:
		return false
	
	if arc_type == "turret":
		return true
	
	var from_pixel = HexCoord.axial_to_pixel(from_pos.x, from_pos.y)
	var target_pixel = HexCoord.axial_to_pixel(target_pos.x, target_pos.y)
	var angle_to_target = rad_to_deg((target_pixel - from_pixel).angle())
	var facing_angle = -from_facing * 60.0
	
	var diff = fmod(fmod(angle_to_target - facing_angle + 540.0, 360.0) + 360.0, 360.0)
	
	match arc_type:
		"forward":
			return diff < arc_angle / 2.0 or diff > 360.0 - arc_angle / 2.0
		"broadside_left":
			return abs(diff - 90.0) < arc_angle / 2.0
		"broadside_right":
			return abs(diff - 270.0) < arc_angle / 2.0
		"rear":
			return abs(diff - 180.0) < arc_angle / 2.0
	
	return false
