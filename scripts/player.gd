extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -580.0
const GRAVITY = 980.0
const DASH_SPEED = 600.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.8
const WALL_JUMP_H = 250.0
const WALL_JUMP_V = -400.0

var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_dashing: bool = false
var _was_on_floor: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var last_dir: float = 1.0
var wall_jump_lockout: float = 0.0

const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1
const JUMP_RELEASE_GRAVITY_MULT = 3.0
const WALL_JUMP_LOCKOUT_TIME = 0.15
const APEX_GRAVITY_MULT = 0.69
const APEX_THRESHOLD = 80.0

var _block_toggle: bool = false
var _bob_time: float = 0.0
var _squash_timer: float = 0.0

const BASE_SCALE := Vector2(0.4, 0.4)
const SQUASH_DURATION := 0.18

func _ready() -> void:
	_block_toggle = true
	$Sprite2D.texture = load("res://assets/sprites/character.png")
	$Sprite2D.scale = BASE_SCALE

func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)
		var grav := GRAVITY
		if velocity.y < 0 and not Input.is_action_pressed("jump"):
			grav *= JUMP_RELEASE_GRAVITY_MULT
		elif abs(velocity.y) < APEX_THRESHOLD:
			grav *= APEX_GRAVITY_MULT
		velocity.y += grav * delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)

	_handle_dash(delta)

	wall_jump_lockout = max(wall_jump_lockout - delta, 0.0)

	if not is_dashing:
		var dir := Input.get_axis("move_left", "move_right")
		if wall_jump_lockout <= 0:
			velocity.x = dir * SPEED
		if dir != 0:
			last_dir = dir
			$Sprite2D.flip_h = dir < 0

		if jump_buffer_timer > 0:
			if coyote_timer > 0:
				velocity.y = JUMP_VELOCITY
				_squash_timer = 0.0
				coyote_timer = 0.0
				jump_buffer_timer = 0.0
				AudioManager.play_sfx("jump")
			elif is_on_wall():
				var normal := get_wall_normal()
				velocity = Vector2(normal.x * WALL_JUMP_H, WALL_JUMP_V)
				_squash_timer = 0.0
				jump_buffer_timer = 0.0
				wall_jump_lockout = WALL_JUMP_LOCKOUT_TIME
				AudioManager.play_sfx("jump")

	if not _block_toggle and Input.is_action_just_pressed("toggle"):
		DayNightManager.toggle()
	_block_toggle = false

	move_and_slide()

	if not _was_on_floor and is_on_floor():
		AudioManager.play_sfx("land")
		_squash_timer = SQUASH_DURATION
	_was_on_floor = is_on_floor()

	_update_sprite(delta)

func reset() -> void:
	velocity = Vector2.ZERO
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	wall_jump_lockout = 0.0
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	_was_on_floor = true
	_squash_timer = 0.0
	_bob_time = 0.0
	_block_toggle = true
	$Sprite2D.scale = BASE_SCALE
	$Sprite2D.rotation = 0.0
	$Sprite2D.position.y = 0.0

func _update_sprite(delta: float) -> void:
	_bob_time += delta
	var target_scale := BASE_SCALE
	var target_rot := 0.0
	var target_y := 0.0

	if _squash_timer > 0.0:
		_squash_timer -= delta
		var t := clampf(_squash_timer / SQUASH_DURATION, 0.0, 1.0)
		target_scale = BASE_SCALE.lerp(Vector2(BASE_SCALE.x * 1.35, BASE_SCALE.y * 0.7), t)
	elif is_dashing:
		target_scale = Vector2(BASE_SCALE.x * 1.4, BASE_SCALE.y * 0.75)
		target_rot = last_dir * 0.12
	elif not is_on_floor():
		if velocity.y < -50.0:
			target_scale = Vector2(BASE_SCALE.x * 0.82, BASE_SCALE.y * 1.18)
			target_rot = -last_dir * 0.06
		else:
			target_scale = Vector2(BASE_SCALE.x * 1.05, BASE_SCALE.y * 0.95)
			target_rot = last_dir * 0.06
	elif abs(velocity.x) > 10.0:
		target_y = sin(_bob_time * 12.0) * 3.0
		target_rot = velocity.x / SPEED * 0.08
	else:
		target_y = sin(_bob_time * 2.5) * 1.5

	$Sprite2D.scale = $Sprite2D.scale.lerp(target_scale, delta * 18.0)
	$Sprite2D.rotation = lerp($Sprite2D.rotation, target_rot, delta * 14.0)
	$Sprite2D.position.y = lerp($Sprite2D.position.y, target_y, delta * 20.0)

func _handle_dash(delta: float) -> void:
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if dash_timer > 0:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		return

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		var dir := Input.get_axis("move_left", "move_right")
		velocity.x = DASH_SPEED * (dir if dir != 0 else last_dir)
		velocity.y = 0.0
		AudioManager.play_sfx("dash")
