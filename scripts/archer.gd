extends CharacterBody2D

@export var projectile_scene: PackedScene
@export var fire_rate: float = 1.2
@export var move_speed: float = 50

@onready var sprite = $AnimatedSprite2D
@onready var detection_area = $Area2D
@onready var fire_timer = $fire_timer

var target_in_range = null

func _ready():
	add_to_group("player")
	fire_timer.wait_time = fire_rate
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	fire_timer.start()

func _physics_process(delta):
	if target_in_range and is_instance_valid(target_in_range):
		# Enemy in range: stop moving and attack
		velocity = Vector2.ZERO
		sprite.play("attack")
	else:
		# No enemy: move forward
		velocity.x = move_speed
		sprite.play("default")

	move_and_slide()

func _on_fire_timer_timeout():
	if target_in_range and is_instance_valid(target_in_range):
		var arrow = projectile_scene.instantiate()
		arrow.position = global_position + Vector2(20, -10)
		arrow.direction = Vector2(1, 0)
		arrow.damage = 3
		get_tree().current_scene.add_child(arrow)

func _on_body_entered(body):
	if body.is_in_group("enemy") and target_in_range == null:
		target_in_range = body

func _on_body_exited(body):
	if body == target_in_range:
		target_in_range = null
