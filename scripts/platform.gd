extends StaticBody2D

enum PlatformType { SOLID, DAY_ONLY, SHADOW_ONLY }

@export var platform_type: PlatformType = PlatformType.SOLID

const TEXTURES = {
	PlatformType.SOLID:       "res://assets/sprites/platform_solid.svg",
	PlatformType.DAY_ONLY:    "res://assets/sprites/platform_day.svg",
	PlatformType.SHADOW_ONLY: "res://assets/sprites/platform_shadow.svg",
}

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.texture = load(TEXTURES[platform_type])
	if sprite.texture and collision.shape is RectangleShape2D:
		var sz: Vector2 = collision.shape.size
		sprite.scale = Vector2(sz.x / sprite.texture.get_width(), sz.y / sprite.texture.get_height())
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
