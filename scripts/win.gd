extends Control

const RETURN_DELAY := 6.0

var _timer: float = 0.0

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= RETURN_DELAY or Input.is_action_just_pressed("jump"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
