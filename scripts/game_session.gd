extends Node

var player_name: String = ""
var run_elapsed_ms: int = 0

var _start_ticks: int = 0
var _running: bool = false

func start_run() -> void:
	_start_ticks = Time.get_ticks_msec()
	_running = true

func stop_run() -> void:
	if not _running:
		return
	run_elapsed_ms = Time.get_ticks_msec() - _start_ticks
	_running = false

static func format_ms(ms: int) -> String:
	var total_s := ms / 1000
	var tenths := (ms % 1000) / 100
	var sec := total_s % 60
	var min := total_s / 60
	return "%d:%02d.%d" % [min, sec, tenths]
