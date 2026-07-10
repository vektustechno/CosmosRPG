class_name ExplosionEffect
extends Node2D

@export var explosion_color: Color = Color.ORANGE
@export var explosion_radius: float = 64.0
@export var particle_count: int = 20
@export var lifetime: float = 0.8

func _ready() -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.amount = particle_count
	particles.direction = Vector2.DOWN
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 200
	particles.lifetime = lifetime
	particles.scale_amount = 1.5
	particles.color = explosion_color
	particles.position = Vector2.ZERO
	add_child(particles)
	
	var flash = ColorRect.new()
	flash.color = Color.WHITE
	flash.size = Vector2(explosion_radius * 2, explosion_radius * 2)
	flash.position = Vector2(-explosion_radius, -explosion_radius)
	add_child(flash)
	
	particles.emitting = true
	
	var tween = create_tween()
	tween.tween_property(flash, "color", Color.TRANSPARENT, lifetime * 0.3)
	tween.tween_callback(_cleanup)

func _cleanup() -> void:
	queue_free()
