extends Area2D

@export var speed = 300
@export var damage = 3
var direction = Vector2(1, 0)

func _ready():
	connect("body_entered", _on_body_entered)

func _process(delta):
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("enemy"):
		body.set_meta("hp", body.get_meta("hp") - damage)
		body.modulate = Color(1, 1, 1)  # Flash white
		body.set_meta("stunned", true)
		
		var bounce = create_tween()
		var origin = body.position
		bounce.tween_property(body, "position", origin + Vector2(-10, 0), 0.1)
		bounce.tween_property(body, "position", origin, 0.3)

		get_parent().show_floating_text(body.position, damage)

		await get_tree().create_timer(0.5).timeout
		body.modulate = Color(1, 1, 1, 1)
		body.set_meta("stunned", false)
		
		queue_free()
