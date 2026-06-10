extends Control

@onready var time_lb_label: Label = $TimeLeaderboardLabel
@onready var dist_lb_label: Label = $DistLeaderboardLabel

func _ready() -> void:
	AudioManager.play_music("menu")
	time_lb_label.text = "Top Times:\nLoading..."
	dist_lb_label.text = "Top Distances:\nLoading..."
	Leaderboard.fetch_top_text("time", 5, func(text: String) -> void:
		time_lb_label.text = "Top Times:\n" + text
	)
	Leaderboard.fetch_top_text("distance", 5, func(text: String) -> void:
		dist_lb_label.text = "Top Distances:\n" + text
	)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
