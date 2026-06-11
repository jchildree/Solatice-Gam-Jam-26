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
var _squash_timer: float = 0.0

const ANIM_SCALE := Vector2(3.0, 3.0)
const ANIM_Y_OFFSET := -76.0
const SQUASH_DURATION := 0.18
const FRAME_SIZE := 72
const NIGHT_TINT := Color(0.62, 0.66, 0.85)

const ANIM_DEFS := {
	"idle": {"sheet": "Idle", "frames": 1, "fps": 1.0, "loop": true},
	"run": {"sheet": "Running", "frames": 12, "fps": 14.0, "loop": true},
	"jump": {"sheet": "Jumping", "frames": 10, "fps": 12.0, "loop": false},
	"fall": {"sheet": "Falling", "frames": 6, "fps": 12.0, "loop": true},
	"land": {"sheet": "Landing", "frames": 6, "fps": 18.0, "loop": false},
	"roll": {"sheet": "Roll", "frames": 9, "fps": 9.0 / DASH_DURATION, "loop": false},
}

var _anim: AnimatedSprite2D

func _ready() -> void:
	_block_toggle = true
	$Sprite2D.visible = false
	_anim = AnimatedSprite2D.new()
	_anim.sprite_frames = _build_frames()
	_anim.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_anim.scale = ANIM_SCALE
	_anim.position.y = ANIM_Y_OFFSET
	add_child(_anim)
	_anim.play("idle")

func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name in ANIM_DEFS:
		var def: Dictionary = ANIM_DEFS[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, def["fps"])
		frames.set_animation_loop(anim_name, def["loop"])
		var tex: Texture2D = load("res://assets/sprites/animations/processed/%s.png" % def["sheet"])
		for i in range(def["frames"]):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex
			atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(anim_name, atlas)
	return frames

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
			_anim.flip_h = dir < 0

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
		_anim.play("land")
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
	_block_toggle = true
	if _anim:
		_anim.scale = ANIM_SCALE
		_anim.position.y = ANIM_Y_OFFSET
		_anim.modulate = Color.WHITE
		_anim.play("idle")

func _update_sprite(delta: float) -> void:
	var target_scale := ANIM_SCALE
	var target_y := ANIM_Y_OFFSET

	if is_dashing:
		if _anim.animation != "roll":
			_anim.play("roll")
	elif not is_on_floor():
		if velocity.y < 0.0:
			if _anim.animation != "jump":
				_anim.play("jump")
		elif _anim.animation != "fall":
			_anim.play("fall")
	elif _anim.animation == "land" and _anim.is_playing() and abs(velocity.x) <= 10.0:
		pass
	elif abs(velocity.x) > 10.0:
		if _anim.animation != "run":
			_anim.play("run")
	elif _anim.animation != "idle":
		_anim.play("idle")

	if _squash_timer > 0.0:
		_squash_timer -= delta
		var t := clampf(_squash_timer / SQUASH_DURATION, 0.0, 1.0)
		target_scale = ANIM_SCALE.lerp(Vector2(ANIM_SCALE.x * 1.35, ANIM_SCALE.y * 0.7), t)

	_anim.scale = _anim.scale.lerp(target_scale, delta * 18.0)
	_anim.position.y = lerp(_anim.position.y, target_y, delta * 20.0)

	var tint := Color.WHITE if DayNightManager.is_day else NIGHT_TINT
	_anim.modulate = _anim.modulate.lerp(tint, delta * 4.0)

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
