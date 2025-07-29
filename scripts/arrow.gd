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

	disconnect("body_entered", _on_body_entered)

	var hp = body.get_meta("hp", 10)
	hp -= damage
	body.set_meta("hp", hp)

	# ✅ Get enemy sprite and flash it
	var sprite = body.get_node("AnimatedSprite2D")
	sprite.modulate = Color(1, 1, 1)

	var flash = create_tween()
	flash.tween_property(sprite, "modulate", Color(1, 1, 1), 0.05)
	flash.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.2)

	# ✅ Bounce
	body.set_meta("stunned", true)
	var origin = body.position
	var bounce = create_tween()
	bounce.tween_property(body, "position", origin + Vector2(-10, 0), 0.1)
	bounce.tween_property(body, "position", origin, 0.2)

	# ✅ Floating damage text
	if get_tree().current_scene.has_method("show_floating_text"):
		get_tree().current_scene.call("show_floating_text", body.position, damage)

	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(body):
		body.set_meta("stunned", false)

	queue_free()
