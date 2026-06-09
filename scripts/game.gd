extends Node2D

const LEVELS = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
	"res://scenes/levels/level_4.tscn",
	"res://scenes/levels/level_5.tscn",
]

const LEVEL_BUDGETS = [60.0, 52.0, 44.0, 37.0, 30.0]

const LEVEL_BOUNDS = [
	Rect2(0, 0, 1280, 720),
	Rect2(0, 0, 1280, 720),
	Rect2(0, 0, 2560, 720),
	Rect2(0, 0, 1280, 1440),
	Rect2(0, 0, 2560, 1440),
]

const LEVEL_BACKGROUNDS = [
	["res://assets/sprites/backgrounds/bg_l1_day.png", "res://assets/sprites/backgrounds/bg_l1_night.png"],
	["res://assets/sprites/backgrounds/bg_l2_day.png", "res://assets/sprites/backgrounds/bg_l2_night.png"],
	["res://assets/sprites/backgrounds/bg_l3_day.png", "res://assets/sprites/backgrounds/bg_l3_night.png"],
	["res://assets/sprites/backgrounds/bg_l4_day.png", "res://assets/sprites/backgrounds/bg_l4_night.png"],
	["res://assets/sprites/backgrounds/bg_l5_day.png", "res://assets/sprites/backgrounds/bg_l5_night.png"],
]

var current_level_index: int = 0
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_saved_time: float = 60.0

@onready var level_container: Node2D = $LevelContainer
@onready var player: CharacterBody2D = $Player
@onready var dusk_timer: Node = $DuskTimer
@onready var camera: Camera2D = $Player/Camera2D
@onready var background: Sprite2D = $BackgroundLayer/Background

func _ready() -> void:
	dusk_timer.dusk_reached.connect(_on_dusk_reached)
	DayNightManager.toggled.connect(_on_toggled)
	load_level(current_level_index)

func _process(_delta: float) -> void:
	var b: Rect2 = LEVEL_BOUNDS[current_level_index]
	var kill_y: float = b.position.y + b.size.y + 300.0
	if player.global_position.y > kill_y:
		player.global_position = checkpoint_position
		player.reset()
		DayNightManager.reset()
		dusk_timer.reset_to_checkpoint(checkpoint_saved_time)

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
	checkpoint_saved_time = LEVEL_BUDGETS[index]
	player.reset()
	var b: Rect2 = LEVEL_BOUNDS[index]
	camera.limit_left = int(b.position.x)
	camera.limit_top = int(b.position.y)
	camera.limit_right = int(b.position.x + b.size.x)
	camera.limit_bottom = int(b.position.y + b.size.y)
	var bg_paths: Array = LEVEL_BACKGROUNDS[index]
	background.set_level_textures(load(bg_paths[0]), load(bg_paths[1]))
	DayNightManager.reset()
	dusk_timer.start(LEVEL_BUDGETS[index])

func _on_dusk_reached() -> void:
	player.global_position = checkpoint_position
	player.reset()
	DayNightManager.reset()
	dusk_timer.reset_to_checkpoint(checkpoint_saved_time)

func _on_toggled(cost: float) -> void:
	dusk_timer.deduct(cost)

func _on_checkpoint_reached(pos: Vector2, saved_time: float) -> void:
	checkpoint_position = pos
	checkpoint_saved_time = saved_time

func _on_level_complete() -> void:
	current_level_index += 1
	if current_level_index >= LEVELS.size():
		get_tree().change_scene_to_file("res://scenes/win.tscn")
	else:
		load_level(current_level_index)
