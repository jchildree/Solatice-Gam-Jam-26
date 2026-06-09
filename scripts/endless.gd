extends Node2D

const CHUNK_WIDTH := 640.0
const SPAWN_LOOKAHEAD := 1280.0
const DESPAWN_BEHIND := 1280.0
const KILL_Y := 1400.0

const DAY_SKY_LAYERS = [
	"res://assets/sprites/backgrounds/sky_day_1.png",
	"res://assets/sprites/backgrounds/sky_day_2.png",
	"res://assets/sprites/backgrounds/sky_day_3.png",
	"res://assets/sprites/backgrounds/sky_day_4.png",
	"res://assets/sprites/backgrounds/sky_day_5.png",
]
const NIGHT_SKY_LAYERS = [
	"res://assets/sprites/backgrounds/sky_night_1.png",
	"res://assets/sprites/backgrounds/sky_night_2.png",
	"res://assets/sprites/backgrounds/sky_night_3.png",
	"res://assets/sprites/backgrounds/sky_night_4.png",
]

@onready var background: Node2D = $BackgroundLayer/Background
@onready var chunk_container: Node2D = $ChunkContainer
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var score_label: Label = $UI/ScoreLabel

var _rng := RandomNumberGenerator.new()
var _next_chunk_x := 0.0
var _entry_y := 400.0
var _last_safe_pos := Vector2(100.0, 360.0)
var _chunks: Array = []
var _done: bool = false

func _ready() -> void:
	_rng.randomize()
	var day_layers: Array = DAY_SKY_LAYERS.map(func(p: String) -> Texture2D: return load(p))
	var night_layers: Array = NIGHT_SKY_LAYERS.map(func(p: String) -> Texture2D: return load(p))
	background.set_level_textures(day_layers, night_layers)
	DayNightManager.reset()
	AudioManager.play_music("day")

	_place_spawn_platform()
	while _next_chunk_x < SPAWN_LOOKAHEAD * 2.0:
		_spawn_chunk()

	camera.limit_left = -200
	camera.limit_right = 10000000
	player.reset()

func _process(_delta: float) -> void:
	if _done:
		return

	if Input.is_action_just_pressed("ui_cancel"):
		_done = true
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		return

	if player.is_on_floor():
		_last_safe_pos = player.global_position

	if player.global_position.y > KILL_Y:
		player.global_position = _last_safe_pos
		player.reset()

	while _next_chunk_x < player.global_position.x + SPAWN_LOOKAHEAD:
		_spawn_chunk()

	_despawn_old_chunks()

	camera.limit_left = int(player.global_position.x) - 400

	var dist := int(player.global_position.x / 50.0)
	score_label.text = "Distance: " + str(dist) + "m"

func _place_spawn_platform() -> void:
	var body := StaticBody2D.new()
	body.set_script(load("res://scripts/platform.gd"))
	body.set("platform_type", 0)
	var cshape := CollisionShape2D.new()
	cshape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(300.0, 16.0)
	cshape.shape = rect
	body.add_child(cshape)
	var spr := Sprite2D.new()
	spr.name = "Sprite2D"
	body.add_child(spr)
	body.position = Vector2(150.0, 400.0)
	chunk_container.add_child(body)

func _spawn_chunk() -> void:
	var chunk := Node2D.new()
	chunk.set_script(load("res://scripts/endless_chunk.gd"))
	chunk.position.x = _next_chunk_x
	chunk_container.add_child(chunk)
	_entry_y = chunk.generate(_rng, _entry_y)
	_chunks.append(chunk)
	_next_chunk_x += CHUNK_WIDTH

func _despawn_old_chunks() -> void:
	var cutoff := player.global_position.x - DESPAWN_BEHIND
	var i := 0
	while i < _chunks.size():
		var c: Node2D = _chunks[i]
		if c.position.x + CHUNK_WIDTH < cutoff:
			c.queue_free()
			_chunks.remove_at(i)
		else:
			i += 1
