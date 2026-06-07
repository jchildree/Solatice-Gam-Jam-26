extends Node2D

const LEVELS = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
	"res://scenes/levels/level_4.tscn",
	"res://scenes/levels/level_5.tscn",
]

var current_level_index: int = 0
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_saved_time: float = 60.0

@onready var level_container: Node2D = $LevelContainer
@onready var player: CharacterBody2D = $Player
@onready var dusk_timer: Node = $DuskTimer

func _ready() -> void:
	dusk_timer.dusk_reached.connect(_on_dusk_reached)
	load_level(current_level_index)

func load_level(index: int) -> void:
	for child in level_container.get_children():
		child.queue_free()

	var scene = load(LEVELS[index])
	var level = scene.instantiate()
	level_container.add_child(level)

	for node in level.find_children("*", "Area2D", true, false):
		if node.is_in_group("checkpoint"):
			node.checkpoint_reached.connect(_on_checkpoint_reached)
		if node.is_in_group("exit"):
			node.level_complete.connect(_on_level_complete)

	var start = level.get_node_or_null("StartPosition")
	if start:
		player.global_position = start.global_position
	checkpoint_position = player.global_position
	checkpoint_saved_time = 60.0
	player.reset()
	DayNightManager.reset()
	dusk_timer.start(60.0)

func _on_dusk_reached() -> void:
	player.global_position = checkpoint_position
	player.reset()
	DayNightManager.reset()
	dusk_timer.reset_to_checkpoint(checkpoint_saved_time)

func _on_checkpoint_reached(pos: Vector2, saved_time: float) -> void:
	checkpoint_position = pos
	checkpoint_saved_time = saved_time

func _on_level_complete() -> void:
	current_level_index += 1
	if current_level_index >= LEVELS.size():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		load_level(current_level_index)
