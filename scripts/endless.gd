extends Node2D

const SPAWN_LOOKAHEAD := 1280.0
const DESPAWN_BEHIND := 1280.0
const KILL_Y := 1400.0

const PLATFORM_SCRIPT := preload("res://scripts/platform.gd")
const CHUNK_SCRIPT := preload("res://scripts/endless_chunk.gd")

@onready var background: Node2D = $BackgroundLayer/Background
@onready var chunk_container: Node2D = $ChunkContainer
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var score_label: Label = $UI/ScoreLabel
@onready var exit_overlay: CanvasLayer = $ExitOverlay
@onready var dist_label: Label = $ExitOverlay/Panel/DistanceLabel
@onready var name_entry: LineEdit = $ExitOverlay/Panel/NameEntry
@onready var submit_btn: Button = $ExitOverlay/Panel/SubmitDistButton
@onready var lb_label: Label = $ExitOverlay/Panel/LeaderboardLabel
@onready var menu_btn: Button = $ExitOverlay/Panel/MenuButton

var _rng := RandomNumberGenerator.new()
var _next_chunk_x := 0.0
var _entry_y := 400.0
var _last_safe_pos := Vector2(100.0, 360.0)
var _chunks: Array = []
var _done: bool = false
var _submitted: bool = false
var _best_distance: int = 0

func _ready() -> void:
	_rng.randomize()
	background.set_level_textures(GameSession.day_sky_textures(), GameSession.night_sky_textures())
	DayNightManager.reset()
	AudioManager.play_music("day")

	_place_spawn_platform()
	while _next_chunk_x < SPAWN_LOOKAHEAD * 2.0:
		_spawn_chunk()

	camera.limit_left = -200
	camera.limit_right = 10000000
	player.reset()

	if GameSession.player_name != "":
		name_entry.text = GameSession.player_name

	submit_btn.pressed.connect(_on_submit_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

func _process(_delta: float) -> void:
	if _done:
		return

	if exit_overlay.visible:
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
	if dist > _best_distance:
		_best_distance = dist
	score_label.text = "Distance: " + str(max(0, dist)) + "m"

	if Input.is_action_just_pressed("ui_cancel"):
		_show_exit_overlay()

func _show_exit_overlay() -> void:
	dist_label.text = "Best Distance: " + str(_best_distance) + "m"
	exit_overlay.visible = true
	name_entry.grab_focus()

func _on_submit_pressed() -> void:
	if _submitted:
		return
	var name_val: String = name_entry.text.strip_edges()
	if name_val == "":
		return
	GameSession.player_name = name_val
	_submitted = true
	submit_btn.disabled = true
	lb_label.text = "Submitting..."
	Leaderboard.submit("distance", name_val, _best_distance)
	Leaderboard.fetch_top_text("distance", 10, func(text: String) -> void:
		lb_label.text = "Top Distances:\n" + text
	)

func _on_menu_pressed() -> void:
	_done = true
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _place_spawn_platform() -> void:
	var body := StaticBody2D.new()
	body.set_script(PLATFORM_SCRIPT)
	body.set("platform_type", PLATFORM_SCRIPT.PlatformType.SOLID)
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
	chunk.set_script(CHUNK_SCRIPT)
	chunk.position.x = _next_chunk_x
	chunk_container.add_child(chunk)
	_entry_y = chunk.generate(_rng, _entry_y)
	_chunks.append(chunk)
	_next_chunk_x += CHUNK_SCRIPT.CHUNK_WIDTH

func _despawn_old_chunks() -> void:
	var cutoff := player.global_position.x - DESPAWN_BEHIND
	var i := 0
	while i < _chunks.size():
		var c: Node2D = _chunks[i]
		if c.position.x + CHUNK_SCRIPT.CHUNK_WIDTH < cutoff:
			c.queue_free()
			_chunks.remove_at(i)
		else:
			i += 1
