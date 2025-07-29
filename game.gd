extends Node2D

@onready var player_tower = $PlayerTower
@onready var enemy_tower = $EnemyTower
@onready var unit_button = $CanvasLayer/SpawnButton
@onready var warrior_button = $CanvasLayer/WarriorButton
@onready var spawn_timer = $EnemySpawnTimer
@onready var money_label = $CanvasLayer/MoneyLabel
@onready var archer_button = $CanvasLayer/ArcherButton
var archer_scene = preload("res://scenes/archer.tscn")
var warrior_scene = preload("res://scenes/warrior.tscn")
var unit_scene = preload("res://scenes/unit.tscn")
var enemy_scene = preload("res://scenes/enemy.tscn")
var floating_text_scene = preload("res://scenes/floating_text.tscn")

var player_units = []
var enemy_units = []

var player_tower_hp = 100
var enemy_tower_hp = 100
var money = 50

func _ready():
	spawn_timer.wait_time = 3.0
	spawn_timer.start()
	unit_button.pressed.connect(spawn_unit)
	warrior_button.pressed.connect(spawn_warrior)
	archer_button.pressed.connect(spawn_archer)
	update_ui()

func _process(delta):
	update_units(delta)
	update_ui()

func update_ui():
	money_label.text = "Money: " + str(money)

func spawn_unit():
	if money < 10:
		return
	money -= 10
	var unit = unit_scene.instantiate()
	unit.position = player_tower.position + Vector2(50, 60)
	unit.set_meta("hp", 10)
	unit.set_meta("damage", 2)
	add_child(unit)
	player_units.append(unit)

func spawn_warrior():
	if money < 30:
		return
	money -= 30
	var unit = warrior_scene.instantiate()
	unit.position = player_tower.position + Vector2(50, 60)
	unit.set_meta("hp", 20)
	unit.set_meta("damage", 3)
	add_child(unit)
	player_units.append(unit)

func _on_enemy_spawn_timer_timeout():
	var enemy = enemy_scene.instantiate()
	enemy.position = enemy_tower.position + Vector2(-50, 60)
	enemy.set_meta("hp", 10)
	enemy.set_meta("damage", 1)
	add_child(enemy)
	enemy_units.append(enemy)

func update_units(delta):
	for unit in player_units:
		if not is_instance_valid(unit): continue
		var enemy = get_closest_target(unit, enemy_units, enemy_tower)
		handle_combat(unit, enemy, false, delta)

	for enemy in enemy_units:
		if not is_instance_valid(enemy): continue
		var target = get_closest_target(enemy, player_units, player_tower)
		handle_combat(enemy, target, true, delta)

func get_closest_target(attacker, unit_list, tower_node):
	for target in unit_list:
		if is_instance_valid(target) and abs(attacker.position.x - target.position.x) < 20:
			return target
	if abs(attacker.position.x - tower_node.position.x) < 20:
		return {"type": "tower", "node": tower_node}
	return null

func handle_combat(attacker, target, is_enemy, delta):
	var anim = attacker.get_node("AnimatedSprite2D")
	var dir = -1 if is_enemy else 1

	if target == null:
		if attacker.get_meta("stunned", false):
			anim.play("default")
			return
		anim.play("default")
		attacker.position.x += dir * 50 * delta
		attacker.set_meta("attack_timer", 0)
	elif typeof(target) == TYPE_DICTIONARY and target.get("type") == "tower":
		anim.play("attack")
		var timer = attacker.get_meta("attack_timer", 0.0)
		timer += delta
		if timer >= 1.0:
			var dmg = attacker.get_meta("damage", 1 if is_enemy else 2)
			if is_enemy:
				player_tower_hp -= dmg
				show_floating_text(player_tower.position, dmg)
			else:
				enemy_tower_hp -= dmg
				show_floating_text(enemy_tower.position, dmg)
			timer = 0
		attacker.set_meta("attack_timer", timer)
	elif is_instance_valid(target):
		anim.play("attack")
		var timer = attacker.get_meta("attack_timer", 0.0)
		timer += delta
		if timer >= 1.0:
			var target_hp = target.get_meta("hp", 10)
			var dmg = attacker.get_meta("damage", 1 if is_enemy else 2)
			target_hp -= dmg
			target.set_meta("hp", target_hp)
			show_floating_text(target.position, dmg)
			if target_hp <= 0:
				if not is_enemy:
					money += 10
				target.queue_free()
				if is_enemy:
					enemy_units.erase(target)
				else:
					player_units.erase(target)
			timer = 0
		attacker.set_meta("attack_timer", timer)

func show_floating_text(pos: Vector2, amount: int):
	var text = floating_text_scene.instantiate()
	text.text = str(amount)
	text.position = pos + Vector2(0, -20)
	add_child(text)

	var tween = create_tween()
	tween.tween_property(text, "position", text.position + Vector2(0, -30), 1.0)
	tween.tween_property(text, "modulate:a", 0, 1.0)
	tween.tween_callback(Callable(text, "queue_free"))

func spawn_archer():
	if money < 40:
		return
	money -= 40
	var unit = archer_scene.instantiate()
	unit.position = player_tower.position + Vector2(50, 60)
	unit.set_meta("hp", 15)
	unit.set_meta("damage", 3)
	add_child(unit)
	player_units.append(unit)
