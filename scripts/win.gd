extends Control

var _done: bool = false
var _submitted: bool = false

func _ready() -> void:
	$VBoxContainer/BonusButton.pressed.connect(_on_bonus_pressed)
	$VBoxContainer/SubmitTimeButton.pressed.connect(_on_submit_pressed)
	Leaderboard.scores_received.connect(_on_scores_received)

	$VBoxContainer/TimeLabel.text = "Time: " + GameSession.format_ms(GameSession.run_elapsed_ms)

	if GameSession.player_name != "":
		$VBoxContainer/NameEntry.text = GameSession.player_name

func _process(_delta: float) -> void:
	if _done:
		return
	if Input.is_action_just_pressed("jump") and not $VBoxContainer/NameEntry.has_focus():
		_done = true
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_submit_pressed() -> void:
	if _submitted:
		return
	var name_val: String = $VBoxContainer/NameEntry.text.strip_edges()
	if name_val == "":
		return
	GameSession.player_name = name_val
	_submitted = true
	$VBoxContainer/SubmitTimeButton.disabled = true
	$VBoxContainer/LeaderboardLabel.text = "Submitting..."
	Leaderboard.submit("time", name_val, GameSession.run_elapsed_ms)
	Leaderboard.fetch("time", 10)

func _on_scores_received(board: String, entries: Array) -> void:
	if board != "time":
		return
	var lines := ["Top Times:"]
	for i in entries.size():
		var e: Dictionary = entries[i]
		lines.append("%d. %-16s %s" % [i + 1, e["name"], GameSession.format_ms(e["score"])])
	$VBoxContainer/LeaderboardLabel.text = "\n".join(lines)

func _on_bonus_pressed() -> void:
	if _done:
		return
	_done = true
	get_tree().change_scene_to_file("res://scenes/endless.tscn")
