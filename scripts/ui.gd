extends CanvasLayer

@onready var timer_bar: ProgressBar = $TimerBar
@onready var cooldown_bar: ProgressBar = $CooldownBar
@onready var state_label: Label = $StateLabel

func _ready() -> void:
	DayNightManager.state_changed.connect(_on_state_changed)
	var dusk_timer = get_tree().get_first_node_in_group("dusk_timer")
	if dusk_timer:
		dusk_timer.time_updated.connect(_on_time_updated)
	_on_state_changed(DayNightManager.is_day)

func _process(_delta: float) -> void:
	cooldown_bar.value = 1.0 - DayNightManager.get_cooldown_percent()

func _on_time_updated(remaining: float, total: float) -> void:
	timer_bar.value = remaining / total

func _on_state_changed(is_day: bool) -> void:
	state_label.text = "DAY" if is_day else "NIGHT"
