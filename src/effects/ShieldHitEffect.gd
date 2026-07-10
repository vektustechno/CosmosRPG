class_name ShieldHitEffect
extends Node2D

@export var shield_color: Color = Color.CYAN

func _ready() -> void:
	var arcs = int(randf_range(3, 6))
	for i in range(arcs):
		var arc = ColorRect.new()
		arc.size = Vector2(4, 16)
		arc.color = shield_color
		arc.modulate = Color.WHITE
		var angle = randf_range(0, TAU)
		var dist = randf_range(20, 50)
		arc.position = Vector2(cos(angle), sin(angle)) * dist
		arc.rotation = angle
		add_child(arc)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.3)
	tween.tween_callback(queue_free)
