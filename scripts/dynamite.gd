extends Node2D

@export var speed := 300.0
@export var explosion_radius := 60
@export var explosion_damage := 6

var thrower: Node = null
var explosion_scene = preload("res://scenes/explosion_particles.tscn")

func _ready():
	set_as_top_level(true)
	connect("body_entered", _on_body_entered)

func _physics_process(delta):
	position += Vector2.LEFT * speed * delta

func _on_body_entered(body):
	if body == thrower:
		return
	
	_explode()

func _explode():
	# Visual explosion effect
	var explosion = explosion_scene.instantiate()
	explosion.position = global_position
	get_tree().current_scene.add_child(explosion)

	# Camera shake
	if get_tree().current_scene.has_method("shake_camera"):
		get_tree().current_scene.call_deferred("shake_camera", 0.2, 6)

	# Deal damage to players in range
	for body in get_tree().get_nodes_in_group("player"):
		if body.global_position.distance_to(global_position) <= explosion_radius:
			var hp = body.get_meta("hp", 10)
			hp -= explosion_damage
			body.set_meta("hp", hp)
			body.set_meta("stunned", true)
			body.modulate = Color(1, 1, 1)  # Visual feedback

			# Knockback effect
			var origin = body.position
			var knockback = create_tween()
			knockback.tween_property(body, "position", origin + Vector2(40, -20), 0.2)
			knockback.tween_property(body, "position", origin, 0.3)

			# Optional damage number
			if get_tree().current_scene.has_method("show_floating_text"):
				get_tree().current_scene.call("show_floating_text", body.position, explosion_damage)

	# Resume thrower's ability
	if thrower and is_instance_valid(thrower):
		thrower.throwing = false

	queue_free()
