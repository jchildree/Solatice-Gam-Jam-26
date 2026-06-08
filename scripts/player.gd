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
var _landing: bool = false

func _ready() -> void:
	_block_toggle = true
	_setup_animations()

func _setup_animations() -> void:
	var frames := SpriteFrames.new()
	var char_tex: Texture2D = load("res://assets/sprites/character.png")
	for anim in ["idle", "run", "jump", "fall", "land", "dash"]:
		frames.add_animation(anim)
		frames.set_animation_speed(anim, 1.0)
		frames.set_animation_loop(anim, anim == "idle" or anim == "run" or anim == "fall")
		frames.add_frame(anim, char_tex)
	$AnimatedSprite2D.sprite_frames = frames
	$AnimatedSprite2D.scale = Vector2(0.4, 0.4)
	$AnimatedSprite2D.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "land":
		_landing = false

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
			$AnimatedSprite2D.flip_h = dir < 0

		if jump_buffer_timer > 0:
			if coyote_timer > 0:
				velocity.y = JUMP_VELOCITY
				_on_jump()
				coyote_timer = 0.0
				jump_buffer_timer = 0.0
				AudioManager.play_sfx("jump")
			elif is_on_wall():
				var normal := get_wall_normal()
				velocity = Vector2(normal.x * WALL_JUMP_H, WALL_JUMP_V)
				_on_jump()
				jump_buffer_timer = 0.0
				wall_jump_lockout = WALL_JUMP_LOCKOUT_TIME
				AudioManager.play_sfx("jump")

	if not _block_toggle and Input.is_action_just_pressed("toggle"):
		DayNightManager.toggle()
	_block_toggle = false

	move_and_slide()

	if not _was_on_floor and is_on_floor():
		AudioManager.play_sfx("land")
		_on_land()
	_was_on_floor = is_on_floor()

	_update_animation()

func reset() -> void:
	velocity = Vector2.ZERO
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	wall_jump_lockout = 0.0
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	_was_on_floor = true
	_landing = false
	$AnimatedSprite2D.play("idle")

func _on_jump() -> void:
	_landing = false

func _on_land() -> void:
	_landing = true
	$AnimatedSprite2D.play("land")

func _update_animation() -> void:
	if _landing:
		return
	if is_dashing:
		_play_anim("dash")
	elif not is_on_floor():
		if velocity.y < -50.0:
			_play_anim("jump")
		else:
			_play_anim("fall")
	elif abs(velocity.x) > 10.0:
		_play_anim("run")
	else:
		_play_anim("idle")

func _play_anim(anim: String) -> void:
	if $AnimatedSprite2D.animation != anim:
		$AnimatedSprite2D.play(anim)

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
