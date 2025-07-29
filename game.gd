extends Node2D

@onready var player_tower = $PlayerTower
@onready var enemy_tower = $EnemyTower
@onready var unit_button = $CanvasLayer/SpawnButton
@onready var warrior_button = $CanvasLayer/WarriorButton
@onready var spawn_timer = $EnemySpawnTimer
@onready var money_label = $CanvasLayer/MoneyLabel
@onready var archer_button = $CanvasLayer/ArcherButton
@onready var camera = $Camera2D
@onready var wave_banner = $CanvasLayer/WaveBanner
@onready var player_tower_hp_bar = $CanvasLayer/PlayerTowerHP
@onready var enemy_tower_hp_bar = $CanvasLayer/EnemyTowerHP
@onready var game_over_label = $CanvasLayer/GameOverLabel
@onready var game_over_dim = $CanvasLayer/GameOverDim
@onready var restart_button = $CanvasLayer/RestartButton
@onready var quit_button = $CanvasLayer/QuitButton
# @onready var tween = create_tween()

# Wave system variables
var wave := 1
var enemies_per_wave := 4
var enemies_left := 0
var wave_in_progress := false

# Preload scene files
var archer_scene = preload("res://scenes/archer.tscn")
var warrior_scene = preload("res://scenes/warrior.tscn")
var unit_scene = preload("res://scenes/unit.tscn")
var enemy_scene = preload("res://scenes/enemy.tscn")
var floating_text_scene = preload("res://scenes/floating_text.tscn")
var hp_bar_scene = preload("res://scenes/hp_bar.tscn")

# Units and enemies
var player_units = []
var enemy_units = []

# Player and enemy towers
var player_tower_hp = 50
var enemy_tower_hp = 50
var money = 50
# Define lane Y positions relative to the towers
var lanes = [40, 60, 80]  # You can adjust these for spacing
var game_over = false
var tween  # Declare the variable without assigning yet

func _ready():
	player_tower_hp_bar.max_value = 50
	player_tower_hp_bar.value = player_tower_hp

	enemy_tower_hp_bar.max_value = 50
	enemy_tower_hp_bar.value = enemy_tower_hp
	
	spawn_timer.wait_time = 3.0
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
	
	if player_tower_hp <= 0:
		show_game_result("Defeat!")
	elif enemy_tower_hp <= 0:
		show_game_result("Victory!")

# Update UI (money display)
func update_ui():
	money_label.text = "Money: " + str(money)
	player_tower_hp_bar.value = player_tower_hp
	enemy_tower_hp_bar.value = enemy_tower_hp

# Spawn basic unit
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
	add_child(unit)
	player_units.append(unit)

	# Add HP bar
	var hp_bar = hp_bar_scene.instantiate()
	hp_bar.position = Vector2(0, -30)  # Position above unit
	unit.add_child(hp_bar)
	unit.set_meta("hp_bar", hp_bar)
	hp_bar.set_health(unit.get_meta("hp"), unit.get_meta("hp"))

# Spawn warrior unit
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
	add_child(unit)
	player_units.append(unit)

	# Add HP bar
	var hp_bar = hp_bar_scene.instantiate()
	hp_bar.position = Vector2(0, -30)  # Position above unit
	unit.add_child(hp_bar)
	unit.set_meta("hp_bar", hp_bar)
	hp_bar.set_health(unit.get_meta("hp"), unit.get_meta("hp"))

# Spawn archer unit
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
	add_child(unit)
	player_units.append(unit)

	# Add HP bar
	var hp_bar = hp_bar_scene.instantiate()
	hp_bar.position = Vector2(0, -30)  # Position above unit
	unit.add_child(hp_bar)
	unit.set_meta("hp_bar", hp_bar)
	hp_bar.set_health(unit.get_meta("hp"), unit.get_meta("hp"))

# Handle enemy spawn timer
func _on_enemy_spawn_timer_timeout():
	if enemies_left <= 0:
		spawn_timer.stop()
		await get_tree().create_timer(5.0).timeout
		next_wave()
		return

	var enemy = enemy_scene.instantiate()
	var lane_y = lanes.pick_random()
	enemy.position = enemy_tower.position + Vector2(-50, lane_y)
	enemy.set_meta("hp", 20 + wave * 2)
	enemy.set_meta("damage", 1)  # Set damage for enemies
	enemy.add_to_group("enemy")
	add_child(enemy)
	enemy_units.append(enemy)

	# Add HP bar
	var hp_bar = hp_bar_scene.instantiate()
	hp_bar.position = Vector2(0, -30)  # Position above enemy
	enemy.add_child(hp_bar)
	enemy.set_meta("hp_bar", hp_bar)
	hp_bar.set_health(enemy.get_meta("hp"), enemy.get_meta("hp"))

	enemies_left -= 1

# Start the wave
func start_wave():
	wave_in_progress = true
	show_wave_banner()
	enemies_left = enemies_per_wave
	spawn_timer.start()

# Move to the next wave
func next_wave():
	wave += 1
	enemies_per_wave += 2
	start_wave()

# Show wave banner animation
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

# Update all units' HP and handle combat
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

# Find closest target (unit or tower)
func get_closest_target(attacker, unit_list, tower_node):
	for target in unit_list:
		if is_instance_valid(target) and abs(attacker.position.x - target.position.x) < 20:
			return target
	if abs(attacker.position.x - tower_node.position.x) < 20:
		return {"type": "tower", "node": tower_node}
	return null

# Handle combat between attacker and target
func handle_combat(attacker, target, is_enemy, delta):
	var anim = attacker.get_node("AnimatedSprite2D")
	var dir = -1 if is_enemy else 1

	# Fix default damage logic
	var default_dmg = 1 if is_enemy else 2
	var dmg = attacker.get_meta("damage", default_dmg)

	if target == null:
		# Move attacker toward target and continue normal attack animation
		anim.play("default")
		attacker.position.x += dir * 50 * delta
		attacker.set_meta("attack_timer", 0)
	elif typeof(target) == TYPE_DICTIONARY and target.get("type") == "tower":
		# Handle damage when attacking towers
		anim.play("attack")
		var timer = attacker.get_meta("attack_timer", 0.0)
		timer += delta
		if timer >= 1.0:
			# Apply damage to the tower
			if is_enemy:
				player_tower_hp = max(player_tower_hp - dmg, 0)
				show_floating_text(player_tower.position, dmg)
			else:
				enemy_tower_hp = max(enemy_tower_hp - dmg, 0)
				show_floating_text(enemy_tower.position, dmg)
			timer = 0
		attacker.set_meta("attack_timer", timer)
	elif is_instance_valid(target):
		# Handle damage when attacking units
		anim.play("attack")
		var timer = attacker.get_meta("attack_timer", 0.0)
		timer += delta
		if timer >= 1.0:
			var target_hp = target.get_meta("hp", 10)
			target_hp -= dmg
			target.set_meta("hp", target_hp)
			# Update HP bar
			if target.has_meta("hp_bar"):
				target.get_meta("hp_bar").set_health(target_hp, target.get_meta("max_hp", target_hp))
			show_floating_text(target.position, dmg)
			if target_hp <= 0:
				# If target dies, give reward and free memory
				if not is_enemy:
					money += 10
				target.queue_free()
				if is_enemy:
					enemy_units.erase(target)
				else:
					player_units.erase(target)
			timer = 0
		attacker.set_meta("attack_timer", timer)

# Show floating damage text above units/towers
func show_floating_text(pos: Vector2, amount: int):
	var text = floating_text_scene.instantiate()
	text.text = str(amount)
	text.position = pos + Vector2(0, -20)
	add_child(text)

	var tween = create_tween()
	tween.tween_property(text, "position", text.position + Vector2(0, -30), 1.0)
	tween.tween_property(text, "modulate:a", 0, 1.0)
	tween.tween_callback(Callable(text, "queue_free"))

# Camera shake effect for impact
func shake_camera(duration := 0.2, intensity := 6):
	var tween = create_tween()
	var random_offset = Vector2(randf() * intensity, randf() * intensity)
	tween.tween_property(camera, "offset", random_offset, duration / 2)
	tween.tween_property(camera, "offset", Vector2.ZERO, duration / 2)

func show_game_result(result_text: String):
	game_over = true
	spawn_timer.stop()

	# Set up UI states
	game_over_label.text = result_text
	game_over_label.visible = true
	game_over_label.modulate.a = 0.0
	game_over_dim.visible = true
	game_over_dim.color.a = 0.0
	restart_button.visible = false
	quit_button.visible = false

	# ✅ Safe to call here because the node is already ready
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
