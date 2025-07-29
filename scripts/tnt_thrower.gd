extends CharacterBody2D

@export var dynamite_scene: PackedScene
@export var throw_rate: float = 2.0
@export var move_speed: float = 40

@onready var sprite = $AnimatedSprite2D
@onready var detection_area = $Area2D
@onready var throw_timer = $throw_timer

var target_in_range = false
var throwing = false

func _ready():
	throw_timer.wait_time = throw_rate
	throw_timer.timeout.connect(_on_throw_timer_timeout)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	throw_timer.start()

func _physics_process(delta):
	if throwing:
		velocity = Vector2.ZERO
		sprite.play("throw")
	else:
		sprite.play("default")
		velocity.x = -move_speed  # Walks left toward player

	move_and_slide()

func _on_body_entered(body):
	if body.is_in_group("player"):
		target_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		target_in_range = false

func _on_throw_timer_timeout():
	if target_in_range and not throwing:
		throwing = true
		var dynamite = dynamite_scene.instantiate()
		dynamite.position = global_position + Vector2(-20, -30)
		dynamite.thrower = self  # Pass reference so it can resume moving later
		get_tree().current_scene.add_child(dynamite)
