extends Sprite2D

var tex_day: Texture2D = null
var tex_night: Texture2D = null

func _ready() -> void:
	centered = false
	DayNightManager.state_changed.connect(_on_state_changed)

func set_level_textures(day: Texture2D, night: Texture2D) -> void:
	tex_day = day
	tex_night = night
	_apply(DayNightManager.is_day)

func _on_state_changed(is_day: bool) -> void:
	_apply(is_day)

func _apply(is_day: bool) -> void:
	texture = tex_day if is_day else tex_night
	if texture:
		var vp: Vector2 = get_viewport_rect().size
		scale = Vector2(vp.x / texture.get_width(), vp.y / texture.get_height())
