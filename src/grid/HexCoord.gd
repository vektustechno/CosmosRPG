class_name HexCoord
extends RefCounted

const HEX_SIZE: float = 16.0
const SQRT3: float = 1.7320508075688772

static func axial_to_pixel(q: float, r: float) -> Vector2:
	var x = HEX_SIZE * (SQRT3 * q + SQRT3 / 2.0 * r)
	var y = HEX_SIZE * (1.5 * r)
	return Vector2(x, y)

static func pixel_to_axial(pos: Vector2) -> Vector2:
	var q = (SQRT3 / 3.0 * pos.x - 1.0 / 3.0 * pos.y) / HEX_SIZE
	var r = (2.0 / 3.0 * pos.y) / HEX_SIZE
	return _axial_round(Vector2(q, r))

static func _axial_round(hex: Vector2) -> Vector2:
	var q = roundi(hex.x)
	var r = roundi(hex.y)
	var s = roundi(-hex.x - hex.y)

	var q_diff = abs(q - hex.x)
	var r_diff = abs(r - hex.y)
	var s_diff = abs(s - (-hex.x - hex.y))

	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s

	return Vector2(q, r)

static func hex_distance(a: Vector2, b: Vector2) -> int:
	var dq = abs(a.x - b.x)
	var dr = abs(a.y - b.y)
	var ds = abs((-a.x - a.y) - (-b.x - b.y))
	return int(max(dq, max(dr, ds)))

static func neighbors(axial: Vector2) -> Array:
	return [
		Vector2(axial.x + 1, axial.y),
		Vector2(axial.x - 1, axial.y),
		Vector2(axial.x, axial.y + 1),
		Vector2(axial.x, axial.y - 1),
		Vector2(axial.x + 1, axial.y - 1),
		Vector2(axial.x - 1, axial.y + 1),
	]

static func hex_corners(center: Vector2, size: float = HEX_SIZE) -> PackedVector2Array:
	var corners = PackedVector2Array()
	for i in range(6):
		var angle = deg_to_rad(60.0 * i - 30.0)
		corners.append(Vector2(
			center.x + size * cos(angle),
			center.y + size * sin(angle)
		))
	return corners

static func line_of_sight(from: Vector2, to: Vector2) -> Array:
	var results = []
	var dist = hex_distance(from, to)
	for i in range(dist + 1):
		var t = 1.0 if dist == 0 else float(i) / float(dist)
		var q = lerp(from.x, to.x, t)
		var r = lerp(from.y, to.y, t)
		results.append(_axial_round(Vector2(q, r)))
	return results
