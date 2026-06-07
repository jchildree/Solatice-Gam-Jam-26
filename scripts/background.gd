extends Sprite2D

const TEX_DAY = preload("res://assets/sprites/sky_day.svg")
const TEX_NIGHT = preload("res://assets/sprites/sky_night.svg")

func _ready() -> void:
	texture = TEX_DAY if DayNightManager.is_day else TEX_NIGHT
	centered = false
	DayNightManager.state_changed.connect(_on_state_changed)

func _on_state_changed(is_day: bool) -> void:
	texture = TEX_DAY if is_day else TEX_NIGHT
