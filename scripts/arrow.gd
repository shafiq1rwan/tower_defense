extends Area2D

@export var speed = 300
@export var damage = 3
var direction = Vector2(1, 0)

func _ready():
	connect("body_entered", _on_body_entered)

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if not is_instance_valid(body): return
	if not body.is_in_group("enemy"): return

	var current_hp = body.get_meta("hp", 10)
	var new_hp = current_hp - damage
	body.set_meta("hp", new_hp)

	if new_hp <= 0:
		# Enemy will be destroyed by global combat logic
		queue_free()
		return

	# Apply stun, flash, bounce
	body.set_meta("stunned", true)
	body.modulate = Color(1, 1, 1)

	var origin = body.position
	var knockback = create_tween()
	knockback.tween_property(body, "position", origin + Vector2(-10, 0), 0.1)
	knockback.tween_property(body, "position", origin, 0.3)

	if get_tree().current_scene.has_method("show_floating_text"):
		get_tree().current_scene.call("show_floating_text", body.position, damage)

	await get_tree().create_timer(0.5).timeout

	if is_instance_valid(body):
		body.modulate = Color(1, 1, 1, 1)
		body.set_meta("stunned", false)

	queue_free()
