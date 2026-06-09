extends Node

const SFX_FILES = {
	"jump":       "res://assets/audio/sfx_jump.wav",
	"dash":       "res://assets/audio/sfx_dash.wav",
	"land":       "res://assets/audio/sfx_land.wav",
	"checkpoint": "res://assets/audio/sfx_checkpoint.wav",
	"complete":   "res://assets/audio/sfx_complete.wav",
}

const MUSIC_FILES = {
	"menu":  "res://assets/audio/music_menu.mp3",
	"day":   "res://assets/audio/music_day.mp3",
	"night": "res://assets/audio/music_night.mp3",
}

const SFX_TONES = {
	"jump":       [660.0, 0.12],
	"dash":       [330.0, 0.08],
	"land":       [110.0, 0.10],
	"checkpoint": [659.0, 0.25],
	"complete":   [880.0, 0.40],
}

var _music: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _sfx_cache: Dictionary = {}
var _current_music: String = ""

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.volume_db = -6.0
	add_child(_music)
	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)
	DayNightManager.state_changed.connect(_on_state_changed)
	for sfx_name in SFX_TONES:
		_get_sfx_tone(sfx_name)

func play_music(key: String) -> void:
	if key == _current_music:
		return
	_current_music = key
	var path: String = MUSIC_FILES.get(key, "")
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream: AudioStreamMP3 = load(path)
	stream.loop = true
	_music.stream = stream
	_music.play()

func play_sfx(name: String) -> void:
	if not SFX_FILES.has(name):
		return
	var path: String = SFX_FILES[name]
	var stream: AudioStream
	if ResourceLoader.exists(path):
		stream = load(path)
	else:
		stream = _get_sfx_tone(name)
	if stream:
		_sfx.stream = stream
		_sfx.play()

func _on_state_changed(is_day: bool) -> void:
	play_music("day" if is_day else "night")

func _get_sfx_tone(name: String) -> AudioStreamWAV:
	if _sfx_cache.has(name):
		return _sfx_cache[name]
	if not SFX_TONES.has(name):
		return null
	var tone := _gen_tone(SFX_TONES[name][0], SFX_TONES[name][1])
	_sfx_cache[name] = tone
	return tone

func _gen_tone(freq: float, duration: float) -> AudioStreamWAV:
	var rate := 44100
	var n := int(duration * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var env := minf(t / 0.005, 1.0) * maxf(1.0 - t / duration, 0.0)
		data.encode_s16(i * 2, int(sin(TAU * freq * t) * env * 24000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = data
	return s
