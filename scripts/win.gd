extends Control

const RETURN_DELAY := 6.0

var _timer: float = 0.0
var _done: bool = false

func _ready() -> void:
	$VBoxContainer/BonusButton.pressed.connect(_on_bonus_pressed)

func _process(delta: float) -> void:
	if _done:
		return
	_timer += delta
	if _timer >= RETURN_DELAY or Input.is_action_just_pressed("jump"):
		_done = true
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_bonus_pressed() -> void:
	if _done:
		return
	_done = true
	get_tree().change_scene_to_file("res://scenes/endless.tscn")
