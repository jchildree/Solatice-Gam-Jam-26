extends Node

const MUSIC = {
	"day":   "res://assets/audio/music_day.ogg",
	"night": "res://assets/audio/music_night.ogg",
}

const SFX = {
	"jump":       "res://assets/audio/sfx_jump.wav",
	"dash":       "res://assets/audio/sfx_dash.wav",
	"land":       "res://assets/audio/sfx_land.wav",
	"checkpoint": "res://assets/audio/sfx_checkpoint.wav",
	"complete":   "res://assets/audio/sfx_complete.wav",
}

var _music: AudioStreamPlayer
var _sfx: AudioStreamPlayer

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)

	_sfx = AudioStreamPlayer.new()
	_sfx.bus = "SFX"
	add_child(_sfx)

	DayNightManager.state_changed.connect(_on_state_changed)
	_play_music("day")

func play_sfx(name: String) -> void:
	if not SFX.has(name):
		return
	var stream = _try_load(SFX[name])
	if stream:
		_sfx.stream = stream
		_sfx.play()

func _on_state_changed(is_day: bool) -> void:
	_play_music("day" if is_day else "night")

func _play_music(key: String) -> void:
	var stream = _try_load(MUSIC[key])
	if stream:
		_music.stream = stream
		_music.play()

# Returns null silently when file is absent so missing assets never crash.
func _try_load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null
