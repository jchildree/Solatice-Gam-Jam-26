extends Area2D

signal checkpoint_reached(position: Vector2, timer_value: float)

@export var saved_time: float = 45.0
var activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if activated or not body.is_in_group("player"):
		return
	activated = true
	emit_signal("checkpoint_reached", global_position, saved_time)
	modulate = Color.YELLOW
	AudioManager.play_sfx("checkpoint")
