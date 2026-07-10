class_name BeamEffect
extends Line2D

@export var beam_color: Color = Color.RED
@export var beam_width: float = 3.0
@export var lifetime: float = 0.15

func fire(from: Vector2, to: Vector2) -> void:
	default_color = beam_color
	width = beam_width
	points = [from, to]
	
	var tween = create_tween()
	tween.tween_property(self, "width", 0.0, lifetime)
	tween.parallel().tween_property(self, "modulate", Color.TRANSPARENT, lifetime)
	tween.tween_callback(queue_free)
