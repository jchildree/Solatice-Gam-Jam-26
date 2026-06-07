extends Node

signal state_changed(is_day: bool)

var is_day: bool = true
var cooldown: float = 3.0
var cooldown_remaining: float = 0.0

func _process(delta: float) -> void:
	if cooldown_remaining > 0:
		cooldown_remaining -= delta

func toggle() -> void:
	if cooldown_remaining > 0:
		return
	is_day = !is_day
	cooldown_remaining = cooldown
	emit_signal("state_changed", is_day)

func get_cooldown_percent() -> float:
	if cooldown <= 0:
		return 0.0
	return cooldown_remaining / cooldown

func is_on_cooldown() -> bool:
	return cooldown_remaining > 0
