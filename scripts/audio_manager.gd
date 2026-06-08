extends Node

const SFX_FILES = {
	"jump":       "res://assets/audio/sfx_jump.wav",
	"dash":       "res://assets/audio/sfx_dash.wav",
	"land":       "res://assets/audio/sfx_land.wav",
	"checkpoint": "res://assets/audio/sfx_checkpoint.wav",
	"complete":   "res://assets/audio/sfx_complete.wav",
}

const MUSIC_FILES = {
	"menu":  "res://assets/audio/music_menu.ogg",
	"day":   "res://assets/audio/music_day.ogg",
	"night": "res://assets/audio/music_night.ogg",
}

# [freq_hz, duration_sec] fallback when file is absent.
const SFX_TONES = {
	"jump":       [660.0, 0.12],
	"dash":       [330.0, 0.08],
	"land":       [110.0, 0.10],
	"checkpoint": [659.0, 0.25],
	"complete":   [880.0, 0.40],
}

# Chord progressions as frequency arrays [root, third, fifth, seventh].
# Each inner array is one chord; beat_sec is seconds per chord; bpm drives rhythmic pulse.
const MUSIC_CHORDS = {
	"menu": {
		"beat_sec": 1.714,
		"bpm": 140.0,
		"chords": [
			[174.61, 220.00, 261.63, 329.63],
			[146.83, 174.61, 220.00, 261.63],
			[130.81, 164.81, 196.00, 246.94],
			[196.00, 246.94, 293.66, 369.99],
		]
	},
	"day": {
		"beat_sec": 2.143,
		"chords": [
			[293.66, 369.99, 440.00, 554.37],
			[246.94, 293.66, 369.99, 440.00],
			[196.00, 246.94, 293.66, 369.99],
			[220.00, 277.18, 329.63, 415.30],
		]
	},
	"night": {
		"beat_sec": 2.143,
		"chords": [
			[146.83, 174.61, 220.00, 261.63],
			[116.54, 146.83, 174.61, 220.00],
			[130.81, 155.56, 196.00, 233.08],
			[110.00, 138.59, 164.81, 207.65],
		]
	},
}

var _music: AudioStreamPlayer
var _sfx: AudioStreamPlayer
var _sfx_cache: Dictionary = {}
var _music_cache: Dictionary = {}
var _current_music: String = ""

func _ready() -> void:
	_music = AudioStreamPlayer.new()
	add_child(_music)
	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)
	DayNightManager.state_changed.connect(_on_state_changed)
	for key in MUSIC_CHORDS:
		_get_music_stream(key)
	for sfx_name in SFX_TONES:
		_get_sfx_tone(sfx_name)

func play_music(key: String) -> void:
	if key == _current_music:
		return
	_current_music = key
	var stream: AudioStream = _try_load(MUSIC_FILES.get(key, ""))
	if not stream:
		stream = _get_music_stream(key)
	if stream:
		_music.stream = stream
		_music.play()

func play_sfx(name: String) -> void:
	if not SFX_FILES.has(name):
		return
	var stream: AudioStream = _try_load(SFX_FILES[name])
	if not stream:
		stream = _get_sfx_tone(name)
	if stream:
		_sfx.stream = stream
		_sfx.play()

func _on_state_changed(is_day: bool) -> void:
	play_music("day" if is_day else "night")

func _try_load(path: String) -> AudioStream:
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null

func _get_sfx_tone(name: String) -> AudioStreamWAV:
	if _sfx_cache.has(name):
		return _sfx_cache[name]
	if not SFX_TONES.has(name):
		return null
	var p: Array = SFX_TONES[name]
	var tone := _gen_tone(p[0], p[1])
	_sfx_cache[name] = tone
	return tone

func _get_music_stream(key: String) -> AudioStreamWAV:
	if _music_cache.has(key):
		return _music_cache[key]
	if not MUSIC_CHORDS.has(key):
		return null
	var def: Dictionary = MUSIC_CHORDS[key]
	var bpm: float = def.get("bpm", 0.0)
	var stream := _gen_chord_loop(def["chords"], def["beat_sec"], bpm)
	_music_cache[key] = stream
	return stream

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

func _gen_chord_loop(chords: Array, beat_sec: float, bpm: float = 0.0) -> AudioStreamWAV:
	var rate := 44100
	var n := int(chords.size() * beat_sec * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	var sub_beat := 60.0 / bpm if bpm > 0.0 else 0.0
	for i in n:
		var t := float(i) / rate
		var chord_t := fmod(t, beat_sec)
		var chord: Array = chords[int(t / beat_sec) % chords.size()]
		var attack := minf(chord_t / 0.15, 1.0)
		var release := 1.0 if chord_t < beat_sec - 0.3 else maxf((beat_sec - chord_t) / 0.3, 0.0)
		var pulse := 1.0
		if sub_beat > 0.0:
			var beat_phase := fmod(t, sub_beat) / sub_beat
			pulse = 1.0 + 0.5 * exp(-beat_phase * 18.0)
		var sample := 0.0
		for freq in chord:
			sample += sin(TAU * freq * t)
		var v := int(sample / chord.size() * attack * release * pulse * 12000.0)
		data.encode_s16(i * 2, clampi(v, -32767, 32767))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = data
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = n - 1
	return s
