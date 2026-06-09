extends Node2D

const CHUNK_WIDTH := 640.0
const PLATFORM_H := 16.0
const MIN_PLATFORM_W := 80.0
const MAX_PLATFORM_W := 200.0
const MIN_GAP := 60.0
const MAX_GAP := 160.0
const MAX_DELTA_Y := 140.0
const Y_MIN := -300.0
const Y_MAX := 1000.0

func generate(rng: RandomNumberGenerator, entry_y: float) -> float:
	var y := clampf(entry_y, Y_MIN, Y_MAX)
	var x := 0.0

	var start_w := rng.randf_range(MIN_PLATFORM_W, MAX_PLATFORM_W)
	_make_platform(x, y, start_w, 0)
	x += start_w

	var count := rng.randi_range(2, 4)
	for _i in count:
		var gap := rng.randf_range(MIN_GAP, MAX_GAP)
		var dy := rng.randf_range(-MAX_DELTA_Y, MAX_DELTA_Y)
		y = clampf(y + dy, Y_MIN, Y_MAX)
		var w := rng.randf_range(MIN_PLATFORM_W, MAX_PLATFORM_W)
		x += gap
		if x + w > CHUNK_WIDTH:
			break
		var ptype := _pick_type(rng)
		_make_platform(x, y, w, ptype)
		x += w

	return y

func _pick_type(rng: RandomNumberGenerator) -> int:
	var r := rng.randf()
	if r < 0.60:
		return 0
	elif r < 0.80:
		return 1
	else:
		return 2

func _make_platform(x: float, y: float, width: float, ptype: int) -> void:
	var body := StaticBody2D.new()
	body.set_script(load("res://scripts/platform.gd"))
	body.set("platform_type", ptype)

	var cshape := CollisionShape2D.new()
	cshape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width, PLATFORM_H)
	cshape.shape = rect
	body.add_child(cshape)

	var spr := Sprite2D.new()
	spr.name = "Sprite2D"
	body.add_child(spr)

	body.position = Vector2(x + width * 0.5, y)
	add_child(body)
