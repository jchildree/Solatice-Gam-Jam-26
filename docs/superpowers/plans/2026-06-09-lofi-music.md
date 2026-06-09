# Lofi Music Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace broken procedural music generation with real lofi OGG tracks for menu, day, and night states.

**Architecture:** Drop-in OGG files into `assets/audio/`. Fix `audio_manager.gd` to enable looping on OGG streams and strip the procedural music generator (keep procedural SFX fallback). One lofi track can serve both day and night states if only one gameplay track is available.

**Tech Stack:** GDScript, Godot 4, AudioStreamOggVorbis, AudioStreamPlayer

---

## Current State

- `assets/audio/` is empty - no audio files exist.
- `audio_manager.gd` falls back to procedural `AudioStreamWAV` chord generation when OGG files are absent.
- The procedural fallback plays but sounds bad.
- OGG loading path exists but is untested because no files are present.
- **Bug:** `play_music()` never sets `loop = true` on loaded OGG streams, so they play once and stop.

---

### Task 1: Source Lofi Music Files

**Files:**
- Add: `assets/audio/music_menu.ogg`
- Add: `assets/audio/music_day.ogg`
- Add: `assets/audio/music_night.ogg`

- [ ] **Step 1: Source royalty-free lofi OGG tracks**

  Find 1-3 lofi tracks in OGG format from a royalty-free source (Pixabay, Free Music Archive, OpenGameArt, etc.). OGG is preferred over MP3 for Godot. WAV works too but is large.

  If you only have one gameplay track, use it for both `music_day.ogg` and `music_night.ogg` - the code handles duplicates fine.

- [ ] **Step 2: Place files**

  Copy tracks to:
  ```
  assets/audio/music_menu.ogg
  assets/audio/music_day.ogg
  assets/audio/music_night.ogg
  ```

- [ ] **Step 3: Import in Godot editor**

  Open the Godot editor. In the FileSystem dock, navigate to `assets/audio/`. Godot auto-imports OGG files on detection. Verify all three appear without error icons.

- [ ] **Step 4: Commit**

  ```bash
  git add assets/audio/music_menu.ogg assets/audio/music_day.ogg assets/audio/music_night.ogg
  git commit -m "feat(audio): add lofi music tracks"
  ```

---

### Task 2: Fix OGG Looping and Strip Procedural Music

**Files:**
- Modify: `scripts/audio_manager.gd`

The `play_music()` function loads an OGG but never enables looping on it. `AudioStreamOggVorbis` has a `loop` property that defaults to `false`. This is why music stops after one play.

The procedural music generator (`MUSIC_CHORDS`, `_gen_chord_loop`, `_get_music_stream`, `_music_cache`) can be removed since real files now exist. SFX procedural fallback stays.

- [ ] **Step 1: Rewrite `audio_manager.gd`**

  Replace the full file with:

  ```gdscript
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
  	var stream: AudioStreamOggVorbis = load(path)
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
  	var p: Array = SFX_TONES[name]
  	var tone := _gen_tone(p[0], p[1])
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
  ```

- [ ] **Step 2: Verify Godot parses with no errors**

  Open Godot editor. Check the Output panel for script errors. Expected: no errors.

- [ ] **Step 3: Commit**

  ```bash
  git add scripts/audio_manager.gd
  git commit -m "fix(audio): loop OGG music, strip procedural music generator"
  ```

---

### Task 3: Manual Playback Verification

No automated tests for audio - verify by running the game.

- [ ] **Step 1: Test menu music**

  Run the game (F5). Expected: lofi track starts playing on the main menu. Let it run for 30+ seconds to confirm it loops.

- [ ] **Step 2: Test gameplay music**

  Start a level. Expected: day music plays. Toggle day/night (E key). Expected: night music switches in. Toggle back. Expected: day music plays again.

- [ ] **Step 3: Test music does not restart on same state**

  Toggle day, then toggle day again quickly. Expected: music does not stutter or restart mid-track (guarded by `_current_music` check).

- [ ] **Step 4: Test SFX still work**

  Jump, dash, land on a platform. Expected: SFX tones play (procedural fallback active since no WAV files exist yet).

- [ ] **Step 5: Commit**

  ```bash
  git commit --allow-empty -m "test(audio): manual verification passed"
  ```

---

## Notes

- `_music.volume_db = -6.0` prevents lofi tracks from overpowering SFX. Adjust to taste.
- Day and night can share the same OGG file if you only have one gameplay track - just copy it to both names.
- If you add real SFX WAV files later, drop them in `assets/audio/` with the names in `SFX_FILES` - no code change needed.
