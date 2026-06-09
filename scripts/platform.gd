extends StaticBody2D

enum PlatformType { SOLID, DAY_ONLY, SHADOW_ONLY }

@export var platform_type: PlatformType = PlatformType.SOLID

const COLORS = {
	PlatformType.SOLID:       Color(0.10, 0.10, 0.18),
	PlatformType.DAY_ONLY:    Color(0.80, 0.60, 0.20),
	PlatformType.SHADOW_ONLY: Color(0.25, 0.20, 0.45),
}

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

static var _tex_cache: Dictionary = {}

func _ready() -> void:
	var sz: Vector2 = (collision.shape as RectangleShape2D).size
	var key := "%d_%d_%d" % [platform_type, int(sz.x), int(sz.y)]
	if not _tex_cache.has(key):
		var img := Image.create(int(sz.x), int(sz.y), false, Image.FORMAT_RGBA8)
		img.fill(COLORS[platform_type])
		_tex_cache[key] = ImageTexture.create_from_image(img)
	sprite.texture = _tex_cache[key]
	DayNightManager.state_changed.connect(_on_state_changed)
	_apply_state(DayNightManager.is_day)

func _on_state_changed(is_day: bool) -> void:
	_apply_state(is_day)

func _apply_state(is_day: bool) -> void:
	match platform_type:
		PlatformType.SOLID:
			pass
		PlatformType.DAY_ONLY:
			collision.set_deferred("disabled", !is_day)
			visible = is_day
		PlatformType.SHADOW_ONLY:
			collision.set_deferred("disabled", is_day)
			visible = !is_day
