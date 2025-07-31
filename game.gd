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

# Preload scenes
var archer_scene = preload("res://scenes/archer.tscn")
var warrior_scene = preload("res://scenes/warrior.tscn")
var unit_scene = preload("res://scenes/unit.tscn")
var enemy_scene = preload("res://scenes/enemy.tscn")
var floating_text_scene = preload("res://scenes/floating_text.tscn")
var hp_bar_scene = preload("res://scenes/hp_bar.tscn")

const ATTACK_RANGE = 60

var wave := 1
var wave_in_progress := false
var player_units = []
var enemy_units = []
var player_tower_hp = 50
var enemy_tower_hp = 50
var money = 50
var lanes = [40, 60, 80]
var lane_index = 0
var game_over = false
var tween

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

	print("[DEBUG] enemy_units:", enemy_units.size(), "spawn queue:", enemies_to_spawn.size(), "in progress:", wave_in_progress)

	if wave_in_progress and enemy_units.is_empty() and enemies_to_spawn.is_empty():
		print("[DEBUG] Wave complete. Starting next wave...")
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

func get_next_lane() -> int:
	var y = lanes[lane_index]
	lane_index = (lane_index + 1) % lanes.size()
	return y

func spawn_unit():
	if money < 10:
		return
	money -= 10
	var unit = unit_scene.instantiate()
	var lane_y = get_next_lane()
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
	var lane_y = get_next_lane()
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
	var lane_y = get_next_lane()
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
	var lane_y = get_next_lane()
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

	await spawn_enemies_slowly()

func spawn_enemies_slowly() -> void:
	await get_tree().process_frame
	for enemy_type in enemies_to_spawn:
		spawn_enemy(enemy_type)
		await get_tree().create_timer(1.0).timeout
	enemies_to_spawn.clear()

func next_wave():
	print("[DEBUG] next_wave() called")
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
		if unit.get_meta("unit_type", "") == "archer": continue
		var enemy = get_closest_target(unit, enemy_units, enemy_tower)
		handle_combat(unit, enemy, false)

	for enemy in enemy_units:
		if not is_instance_valid(enemy): continue
		var target = get_closest_target(enemy, player_units, player_tower)
		handle_combat(enemy, target, true)

func get_closest_target(attacker, unit_list, tower_node):
	for target in unit_list:
		if is_instance_valid(target) and abs(attacker.position.x - target.position.x) < ATTACK_RANGE:
			return target
	if abs(attacker.position.x - tower_node.position.x) < ATTACK_RANGE:
		return {"type": "tower", "node": tower_node}
	return null

func handle_combat(attacker, target, is_enemy):
	var anim = attacker.get_node("AnimatedSprite2D")
	var dir = -1 if is_enemy else 1

	if target == null:
		anim.play("default")
		attacker.position.x += dir * 50 * get_process_delta_time()
		attacker.set_meta("attacking", false)
	elif typeof(target) == TYPE_DICTIONARY and target.get("type") == "tower":
		if not attacker.get_meta("attacking", false):
			attacker.set_meta("attacking", true)
			attack_tower(attacker, target, is_enemy)
	elif is_instance_valid(target):
		if not attacker.get_meta("attacking", false):
			attacker.set_meta("attacking", true)
			attack_unit(attacker, target, is_enemy)

func attack_tower(attacker, target_dict, is_enemy):
	if not is_instance_valid(attacker): return
	var anim = attacker.get_node("AnimatedSprite2D")
	anim.play("attack")
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(attacker): return

	var dmg = attacker.get_meta("damage", is_enemy if 1 else 2)
	if is_enemy:
		player_tower_hp = max(player_tower_hp - dmg, 0)
		show_floating_text(player_tower.position, dmg)
		shake_node(player_tower)
	else:
		enemy_tower_hp = max(enemy_tower_hp - dmg, 0)
		show_floating_text(enemy_tower.position, dmg)
		shake_node(enemy_tower)

	attacker.set_meta("attacking", false)

func attack_unit(attacker, target, is_enemy):
	if not is_instance_valid(attacker): return
	var anim = attacker.get_node("AnimatedSprite2D")
	anim.play("attack")
	await get_tree().create_timer(0.5).timeout
	if not is_instance_valid(attacker): return
	if not is_instance_valid(target): 
		attacker.set_meta("attacking", false)
		return

	if not target.has_meta("hp"):
		attacker.set_meta("attacking", false)
		return

	var dmg = attacker.get_meta("damage", is_enemy if 1 else 2)
	var target_hp = target.get_meta("hp") - dmg
	target.set_meta("hp", target_hp)

	if target.has_meta("hp_bar") and is_instance_valid(target.get_meta("hp_bar")):
		var max_hp = target.get_meta("max_hp") if target.has_meta("max_hp") else target_hp
		target.get_meta("hp_bar").set_health(target_hp, max_hp)
	show_floating_text(target.position, dmg)

	if target_hp <= 0:
		if not is_enemy:
			money += 10
		if is_enemy and enemy_units.has(target):
			enemy_units.erase(target)
		elif not is_enemy and player_units.has(target):
			player_units.erase(target)
		target.queue_free()

	attacker.set_meta("attacking", false)

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
	var offset = Vector2(randf() * intensity, randf() * intensity)
	tween.tween_property(camera, "offset", offset, duration / 2)
	tween.tween_property(camera, "offset", Vector2.ZERO, duration / 2)

func shake_node(node: Node2D, duration := 0.2, intensity := 5):
	var tween = create_tween()
	var original = node.position
	var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	tween.tween_property(node, "position", original + offset, duration / 2)
	tween.tween_property(node, "position", original, duration / 2)

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

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	get_tree().quit()
