extends Node2D

const STEPS = [
	{ "actions": ["move_left", "move_right"], "prompt": "Press A or D to move" },
	{ "actions": ["jump"], "prompt": "Press Space to jump" },
	{ "actions": ["dash"], "prompt": "Press Ctrl to dash" },
	{ "actions": ["toggle"], "prompt": "Press E to toggle day and night" },
]

var current_step: int = 0

@onready var prompt_label: Label = $UI/PromptLabel

func _ready() -> void:
	var day_layers: Array = [
		"res://assets/sprites/backgrounds/sky_day_1.png",
		"res://assets/sprites/backgrounds/sky_day_2.png",
		"res://assets/sprites/backgrounds/sky_day_3.png",
		"res://assets/sprites/backgrounds/sky_day_4.png",
		"res://assets/sprites/backgrounds/sky_day_5.png",
	].map(func(p: String) -> Texture2D: return load(p))
	var night_layers: Array = [
		"res://assets/sprites/backgrounds/sky_night_1.png",
		"res://assets/sprites/backgrounds/sky_night_2.png",
		"res://assets/sprites/backgrounds/sky_night_3.png",
		"res://assets/sprites/backgrounds/sky_night_4.png",
	].map(func(p: String) -> Texture2D: return load(p))
	$Background.set_level_textures(day_layers, night_layers)
	_show_step(0)
	AudioManager.play_music("day")
	$KillZone.body_entered.connect(_on_kill_zone_entered)

func _process(_delta: float) -> void:
	if current_step >= STEPS.size():
		return
	for action in STEPS[current_step]["actions"]:
		if Input.is_action_just_pressed(action):
			_advance()
			return

func _advance() -> void:
	current_step += 1
	if current_step >= STEPS.size():
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		_show_step(current_step)

func _show_step(index: int) -> void:
	prompt_label.text = STEPS[index]["prompt"]

func _on_kill_zone_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.global_position = Vector2(200, 340)
		body.reset()
		DayNightManager.reset()
