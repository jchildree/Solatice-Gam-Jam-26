extends Control

@onready var time_lb_label: Label = $TimeLeaderboardLabel
@onready var dist_lb_label: Label = $DistLeaderboardLabel

func _ready() -> void:
	AudioManager.play_music("menu")
	Leaderboard.scores_received.connect(_on_scores_received)
	Leaderboard.fetch("time", 5)
	Leaderboard.fetch("distance", 5)
	time_lb_label.text = "Top Times:\nLoading..."
	dist_lb_label.text = "Top Distances:\nLoading..."

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_scores_received(board: String, entries: Array) -> void:
	if board == "time":
		var lines := ["Top Times:"]
		for i in entries.size():
			lines.append("%d. %-14s %s" % [i + 1, entries[i]["name"], GameSession.format_ms(entries[i]["score"])])
		time_lb_label.text = "\n".join(lines)
	elif board == "distance":
		var lines := ["Top Distances:"]
		for i in entries.size():
			lines.append("%d. %-14s %dm" % [i + 1, entries[i]["name"], entries[i]["score"]])
		dist_lb_label.text = "\n".join(lines)
