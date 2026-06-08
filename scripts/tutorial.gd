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
	$Background.set_level_textures(
		load("res://assets/sprites/backgrounds/bg_l1_day.png"),
		load("res://assets/sprites/backgrounds/bg_l1_night.png")
	)
	_show_step(0)
	AudioManager.play_music("day")

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
