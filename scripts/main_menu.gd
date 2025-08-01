extends Node2D # or Control, depending on your root node

@onready var start_button = $Control/Background/StartButton
@onready var quit_button = $Control/Background/ExitButton

func _ready():
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	# Change to your game scene path
	get_tree().change_scene_to_file("res://Game.tscn")

func _on_quit_button_pressed():
	get_tree().quit()
