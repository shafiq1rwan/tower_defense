extends Node2D

@export var explosion_radius = 60
@export var explosion_damage = 6
@export var arc_height = -80
@export var arc_duration = 0.6

var thrower: Node = null
var explosion_scene = preload("res://scenes/explosion_particles.tscn")

func _ready():
	var start_pos = position
	var peak_pos = start_pos + Vector2(40, arc_height)
	var end_pos = start_pos + Vector2(80, 0)

	var tween = create_tween()
	tween.tween_property(self, "position", peak_pos, arc_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", end_pos, arc_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(Callable(self, "_explode"))

func _explode():
	# Add explosion visual
	var explosion = explosion_scene.instantiate()
	explosion.position = global_position
	get_tree().current_scene.add_child(explosion)

	# Camera shake
	get_tree().current_scene.call_deferred("shake_camera", 0.2, 6)

	# Damage player units nearby
	for body in get_tree().get_nodes_in_group("player"):
		if body.global_position.distance_to(global_position) <= explosion_radius:
			# damage logic
			var hp = body.get_meta("hp", 10)
			hp -= explosion_damage
			body.set_meta("hp", hp)
			body.set_meta("stunned", true)
			body.modulate = Color(1, 1, 1)  # Flash white

			# Knockback
			var origin = body.position
			var knockback = create_tween()
			knockback.tween_property(body, "position", origin + Vector2(40, -20), 0.2)
			knockback.tween_property(body, "position", origin, 0.3)

			# Optional: floating text
			if get_tree().current_scene.has_method("show_floating_text"):
				get_tree().current_scene.call("show_floating_text", body.position, explosion_damage)

	# Resume movement after short delay
	await get_tree().create_timer(0.6).timeout
	if thrower:
		thrower.throwing = false
	queue_free()
