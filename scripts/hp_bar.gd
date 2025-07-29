extends Node2D

@onready var bar = $Bar

func set_health(current: int, max: int):
	bar.max_value = max
	bar.value = current
