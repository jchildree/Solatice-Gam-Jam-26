extends Area2D

signal level_complete

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		AudioManager.play_sfx("complete")
		emit_signal("level_complete")
