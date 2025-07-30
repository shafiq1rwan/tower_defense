extends Node2D

@onready var units_root = $UnitsRoot
@onready var player_tower = $PlayerTower
@onready var enemy_tower = $EnemyTower
@onready var unit_button = $CanvasLayer/SpawnButton
@onready var warrior_button = $CanvasLayer/WarriorButton
@onready var archer_button = $CanvasLayer/ArcherButton
@onready var money_label = $CanvasLayer/MoneyLabel
@onready var camera = $Camera2D
@onready var wave_banner = $CanvasLayer/WaveBanner
@onready var player_tower_hp_bar = $CanvasLayer/PlayerTowerHP
@onready var enemy_tower_hp_bar = $CanvasLayer/EnemyTowerHP
@onready var game_over_label = $CanvasLayer/GameOverLabel
@onready var game_over_dim = $CanvasLayer/GameOverDim
@onready var restart_button = $CanvasLayer/RestartButton
@onready var quit_button = $CanvasLayer/QuitButton

# Preload scene files
var archer_scene = preload("res://scenes/archer.tscn")
var warrior_scene = preload("res://scenes/warrior.tscn")
var unit_scene = preload("res://scenes/unit.tscn")
var enemy_scene = preload("res://scenes/enemy.tscn")
var floating_text_scene = preload("res://scenes/floating_text.tscn")
var hp_bar_scene = preload("res://scenes/hp_bar.tscn")

# Constants
const ATTACK_RANGE = 40

# Game state
var wave := 1
var wave_in_progress := false
var player_units = []
var enemy_units = []
var player_tower_hp = 50
var enemy_tower_hp = 50
var money = 50
var lanes = [40, 60, 80]
var game_over = false
var tween

# Wave definitions
var waves = [
	[{ "type": "normal", "count": 4 }],
	[{ "type": "normal", "count": 6 }],
	[{ "type": "normal", "count": 4 }, { "type": "strong", "count": 1 }],
]

var current_wave_plan = []
var enemies_to_spawn = []

func _ready():
	units_root.y_sort_enabled = true
	player_tower_hp_bar.max_value = 50
	player_tower_hp_bar.value = player_tower_hp
	enemy_tower_hp_bar.max_value = 50
	enemy_tower_hp_bar.value = enemy_tower_hp

	unit_button.pressed.connect(spawn_unit)
	warrior_button.pressed.connect(spawn_warrior)
	archer_button.pressed.connect(spawn_archer)
	start_wave()
	update_ui()

func _process(delta):
	if game_over:
		return

	update_units(delta)
	update_ui()

	if wave_in_progress and enemy_units.is_empty() and enemies_to_spawn.is_empty():
		wave_in_progress = false
		await get_tree().create_timer(1.0).timeout
		next_wave()

	if player_tower_hp <= 0:
		show_game_result("Defeat!")
	elif enemy_tower_hp <= 0:
		show_game_result("Victory!")

func update_ui():
	money_label.text = "Money: " + str(money)
	player_tower_hp_bar.value = player_tower_hp
	enemy_tower_hp_bar.value = enemy_tower_hp

func spawn_unit():
	if money < 10:
		return
	money -= 10
	var unit = unit_scene.instantiate()
	var lane_y = lanes.pick_random()
	unit.position = player_tower.position + Vector2(50, lane_y)
	unit.set_meta("hp", 10)
	unit.set_meta("damage", 2)
	unit.add_to_group("player")
	unit.set_meta("unit_type", "melee")
	units_root.add_child(unit)
	player_units.append(unit)

	var hp_bar = hp_bar_scene.instantiate()
	hp_bar.position = Vector2(0, -30)
	unit.add_child(hp_bar)
	unit.set_meta("hp_bar", hp_bar)
	hp_bar.set_health(unit.get_meta("hp"), unit.get_meta("hp"))

func spawn_warrior():
	if money < 30:
		return
	money -= 30
	var unit = warrior_scene.instantiate()
	var lane_y = lanes.pick_random()
	unit.position = player_tower.position + Vector2(50, lane_y)
	unit.set_meta("hp", 20)
	unit.set_meta("damage", 3)
	unit.add_to_group("player")
	unit.set_meta("unit_type", "melee")
	units_root.add_child(unit)
	player_units.append(unit)

	var hp_bar = hp_bar_scene.instantiate()
	hp_bar.position = Vector2(0, -30)
	unit.add_child(hp_bar)
	unit.set_meta("hp_bar", hp_bar)
	hp_bar.set_health(unit.get_meta("hp"), unit.get_meta("hp"))

func spawn_archer():
	if money < 40:
		return
	money -= 40
	var unit = archer_scene.instantiate()
	var lane_y = lanes.pick_random()
	unit.position = player_tower.position + Vector2(50, lane_y)
	unit.set_meta("hp", 15)
	unit.set_meta("damage", 3)
	unit.add_to_group("player")
	unit.set_meta("unit_type", "archer")
	units_root.add_child(unit)
	player_units.append(unit)

	var hp_bar = hp_bar_scene.instantiate()
	hp_bar.position = Vector2(0, -30)
	unit.add_child(hp_bar)
	unit.set_meta("hp_bar", hp_bar)
	hp_bar.set_health(unit.get_meta("hp"), unit.get_meta("hp"))

func spawn_enemy(enemy_type: String):
	var enemy = enemy_scene.instantiate()
	var lane_y = lanes.pick_random()
	enemy.position = enemy_tower.position + Vector2(-50, lane_y)

	if enemy_type == "strong":
		enemy.set_meta("hp", 30 + wave * 2)
		enemy.set_meta("damage", 2)
	else:
		enemy.set_meta("hp", 20 + wave * 2)
		enemy.set_meta("damage", 1)

	enemy.add_to_group("enemy")
	units_root.add_child(enemy)
	enemy_units.append(enemy)

	var hp_bar = hp_bar_scene.instantiate()
	hp_bar.position = Vector2(0, -30)
	enemy.add_child(hp_bar)
	enemy.set_meta("hp_bar", hp_bar)
	hp_bar.set_health(enemy.get_meta("hp"), enemy.get_meta("hp"))

func start_wave():
	wave_in_progress = true
	show_wave_banner()

	if wave - 1 < waves.size():
		current_wave_plan = waves[wave - 1]
	else:
		current_wave_plan = [{ "type": "normal", "count": 6 + wave }]

	enemies_to_spawn.clear()
	for entry in current_wave_plan:
		for i in range(entry["count"]):
			enemies_to_spawn.append(entry["type"])

	spawn_enemies_slowly()

func spawn_enemies_slowly():
	await get_tree().process_frame
	for enemy_type in enemies_to_spawn:
		spawn_enemy(enemy_type)
		await get_tree().create_timer(1.0).timeout
	enemies_to_spawn.clear()

func next_wave():
	wave += 1
	start_wave()

func show_wave_banner():
	wave_banner.text = "Wave " + str(wave)
	wave_banner.visible = true
	wave_banner.modulate = Color(1, 1, 1, 0)
	wave_banner.scale = Vector2(0.8, 0.8)

	var tween = create_tween()
	tween.tween_property(wave_banner, "modulate:a", 1.0, 0.4)
	tween.tween_property(wave_banner, "scale", Vector2(1.1, 1.1), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.2)
	tween.tween_property(wave_banner, "modulate:a", 0, 0.5)
	tween.tween_callback(Callable(wave_banner, "hide"))

func update_units(delta):
	for unit in player_units:
		if not is_instance_valid(unit): continue
		if unit.get_meta("unit_type", "") == "archer":
			continue
		var enemy = get_closest_target(unit, enemy_units, enemy_tower)
		handle_combat(unit, enemy, false, delta)

	for enemy in enemy_units:
		if not is_instance_valid(enemy): continue
		var target = get_closest_target(enemy, player_units, player_tower)
		handle_combat(enemy, target, true, delta)

func get_closest_target(attacker, unit_list, tower_node):
	for target in unit_list:
		if is_instance_valid(target) and abs(attacker.position.x - target.position.x) < ATTACK_RANGE:
			return target
	if abs(attacker.position.x - tower_node.position.x) < ATTACK_RANGE:
		return {"type": "tower", "node": tower_node}
	return null

func handle_combat(attacker, target, is_enemy, delta):
	var anim = attacker.get_node("AnimatedSprite2D")
	var dir = -1 if is_enemy else 1
	var dmg = attacker.get_meta("damage", is_enemy if 1 else 2)

	if target == null:
		anim.play("default")
		attacker.position.x += dir * 50 * delta
		attacker.set_meta("attack_timer", 0)
	elif typeof(target) == TYPE_DICTIONARY and target.get("type") == "tower":
		anim.play("attack")
		var timer = attacker.get_meta("attack_timer", 0.0)
		timer += delta
		if timer >= 1.0:
			if is_enemy:
				player_tower_hp = max(player_tower_hp - dmg, 0)
				show_floating_text(player_tower.position, dmg)
				shake_node(player_tower)  # 👈 Shake when damaged
			else:
				enemy_tower_hp = max(enemy_tower_hp - dmg, 0)
				show_floating_text(enemy_tower.position, dmg)
				shake_node(enemy_tower)  # 👈 Shake when damaged
			timer = 0
		attacker.set_meta("attack_timer", timer)
	elif is_instance_valid(target):
		anim.play("attack")
		var timer = attacker.get_meta("attack_timer", 0.0)
		timer += delta
		if timer >= 1.0:
			var target_hp = target.get_meta("hp", 10)
			target_hp -= dmg
			target.set_meta("hp", target_hp)

			if target.has_meta("hp_bar"):
				target.get_meta("hp_bar").set_health(target_hp, target.get_meta("max_hp", target_hp))
			show_floating_text(target.position, dmg)

			if target_hp <= 0:
				if not is_enemy:
					money += 10
				if is_enemy and enemy_units.has(target):
					enemy_units.erase(target)
				elif not is_enemy and player_units.has(target):
					player_units.erase(target)
				target.queue_free()

			timer = 0
		attacker.set_meta("attack_timer", timer)

func show_floating_text(pos: Vector2, amount: int):
	var text = floating_text_scene.instantiate()
	text.text = str(amount)
	text.position = pos + Vector2(0, -20)
	units_root.add_child(text)

	var tween = create_tween()
	tween.tween_property(text, "position", text.position + Vector2(0, -30), 1.0)
	tween.tween_property(text, "modulate:a", 0, 1.0)
	tween.tween_callback(Callable(text, "queue_free"))

func shake_camera(duration := 0.2, intensity := 6):
	var tween = create_tween()
	var random_offset = Vector2(randf() * intensity, randf() * intensity)
	tween.tween_property(camera, "offset", random_offset, duration / 2)
	tween.tween_property(camera, "offset", Vector2.ZERO, duration / 2)

func shake_node(node: Node2D, duration := 0.2, intensity := 5):  # ✅ NEW
	var tween = create_tween()
	var original_pos = node.position
	var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	tween.tween_property(node, "position", original_pos + offset, duration / 2)
	tween.tween_property(node, "position", original_pos, duration / 2)

func show_game_result(result_text: String):
	game_over = true
	game_over_label.text = result_text
	game_over_label.visible = true
	game_over_label.modulate.a = 0.0
	game_over_dim.visible = true
	game_over_dim.color.a = 0.0
	restart_button.visible = false
	quit_button.visible = false

	tween = create_tween()
	tween.tween_property(game_over_label, "modulate:a", 1.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(game_over_dim, "color:a", 0.5, 1.0).set_trans(Tween.TRANS_LINEAR)
	tween.tween_interval(0.5)
	tween.tween_callback(Callable(self, "_on_game_over_animation_finished"))

func _on_game_over_animation_finished():
	restart_button.visible = true
	quit_button.visible = true

func _on_restart_button_pressed() -> void:
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
