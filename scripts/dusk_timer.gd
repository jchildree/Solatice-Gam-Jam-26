extends Node

signal dusk_reached
signal time_updated(remaining: float, total: float)

var total_time: float = 60.0
var remaining: float = 60.0
var active: bool = false

func _process(delta: float) -> void:
	if not active:
		return
	remaining = maxf(remaining - delta, 0.0)
	emit_signal("time_updated", remaining, total_time)
	if remaining <= 0:
		active = false
		emit_signal("dusk_reached")

func start(time: float = 60.0) -> void:
	total_time = time
	remaining = time
	active = true

func reset_to_checkpoint(saved_time: float) -> void:
	remaining = saved_time
	active = true

func pause() -> void:
	active = false

func resume() -> void:
	active = true
