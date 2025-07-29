extends CharacterBody2D

@export var dynamite_scene: PackedScene
@export var throw_rate: float = 2.0
@export var move_speed: float = 40

@onready var sprite = $AnimatedSprite2D
@onready var detection_area = $Area2D
@onready var throw_timer = $throw_timer

var target_in_range: Node = null
var throwing: bool = false

func _ready():
	add_to_group("enemy")

	throw_timer.wait_time = throw_rate
	throw_timer.timeout.connect(_on_throw_timer_timeout)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

	throw_timer.start()

func _physics_process(delta):
	if target_in_range and is_instance_valid(target_in_range):
		# Stop and attack
		velocity = Vector2.ZERO
		if sprite.animation != "attack":
			sprite.play("attack")
	else:
		# Walk toward the tower
		velocity.x = -move_speed
		if sprite.animation != "default":
			sprite.play("default")

	move_and_slide()

func _on_body_entered(body):
	if body.is_in_group("player") and target_in_range == null:
		target_in_range = body
		_on_throw_timer_timeout()  # throw immediately upon detection

func _on_body_exited(body):
	if body == target_in_range:
		target_in_range = null

func _on_throw_timer_timeout():
	if target_in_range and is_instance_valid(target_in_range):
		var dynamite = dynamite_scene.instantiate()
		dynamite.position = global_position + Vector2(-20, -30)
		dynamite.thrower = self
		get_tree().current_scene.add_child(dynamite)

		# Prevent constant throwing
		throw_timer.start()
