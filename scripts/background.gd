extends Node2D

const DAY_SCROLL_SPEEDS = [0.0, 20.0, 10.0, 30.0, 50.0]
const NIGHT_SCROLL_SPEEDS = [0.0, 0.0, 15.0, 30.0]

var _day_groups: Array = []
var _night_groups: Array = []
var _day_offsets: Array = []
var _night_offsets: Array = []

func _ready() -> void:
	DayNightManager.state_changed.connect(_on_state_changed)

func set_level_textures(day_layers: Array, night_layers: Array) -> void:
	for group in _day_groups:
		for s in group:
			s.queue_free()
	for group in _night_groups:
		for s in group:
			s.queue_free()
	_day_groups.clear()
	_night_groups.clear()
	_day_offsets.clear()
	_night_offsets.clear()

	var vp: Vector2 = get_viewport_rect().size

	for i in day_layers.size():
		var tex: Texture2D = day_layers[i]
		if tex == null:
			continue
		var group: Array = []
		for j in 2:
			var s := Sprite2D.new()
			s.centered = false
			s.texture = tex
			s.scale = Vector2(vp.x / tex.get_width(), vp.y / tex.get_height())
			s.position.x = j * vp.x
			add_child(s)
			group.append(s)
		_day_groups.append(group)
		_day_offsets.append(0.0)

	for i in night_layers.size():
		var tex: Texture2D = night_layers[i]
		if tex == null:
			continue
		var group: Array = []
		for j in 2:
			var s := Sprite2D.new()
			s.centered = false
			s.texture = tex
			s.scale = Vector2(vp.x / tex.get_width(), vp.y / tex.get_height())
			s.position.x = j * vp.x
			add_child(s)
			group.append(s)
		_night_groups.append(group)
		_night_offsets.append(0.0)

	_apply(DayNightManager.is_day)

func _process(delta: float) -> void:
	var vp_w: float = get_viewport_rect().size.x
	if DayNightManager.is_day:
		_scroll(_day_groups, _day_offsets, DAY_SCROLL_SPEEDS, vp_w, delta)
	else:
		_scroll(_night_groups, _night_offsets, NIGHT_SCROLL_SPEEDS, vp_w, delta)

func _scroll(groups: Array, offsets: Array, speeds: Array, vp_w: float, delta: float) -> void:
	for i in groups.size():
		var spd: float = speeds[min(i, speeds.size() - 1)]
		if spd <= 0.0:
			continue
		offsets[i] -= spd * delta
		if offsets[i] <= -vp_w:
			offsets[i] += vp_w
		for j in 2:
			groups[i][j].position.x = offsets[i] + j * vp_w

func _on_state_changed(is_day: bool) -> void:
	_apply(is_day)

func _apply(is_day: bool) -> void:
	for group in _day_groups:
		for s in group:
			s.visible = is_day
	for group in _night_groups:
		for s in group:
			s.visible = not is_day
