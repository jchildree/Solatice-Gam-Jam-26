# Leaderboard and Global Timer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a global online leaderboard for the bonus level (distance) and a global timer that tracks total time to beat all 5 main levels, with top-10 submission for both.

**Architecture:** Two dreamlo.com leaderboard boards (one per feature, each requires a free account). A `GameSession` autoload holds run-timer state and player name across scene changes. A `Leaderboard` autoload wraps Godot `HTTPRequest` nodes for fire-and-forget submit and async fetch. Win screen gains a time display + name entry + top-10 view. Endless scene gains an exit overlay with the same pattern.

**Tech Stack:** Godot 4.3+ GDScript, dreamlo.com free leaderboard API (HTTP GET, pipe-delimited response), Godot `HTTPRequest` node.

---

## Prerequisites - Register dreamlo Boards

You need **two free dreamlo accounts** (one per board). Do this before writing any code.

1. Go to `http://dreamlo.com` and click "Get your leaderboard".
2. Register account #1 (for the main-game completion time board). Save the **private key** and **public key** shown on the dashboard.
3. Register account #2 (for the bonus level distance board). Save both keys.

You will substitute these four keys into `scripts/leaderboard.gd` in Task 2.

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `project.godot` | Modify | Register `GameSession` and `Leaderboard` autoloads |
| `scripts/game_session.gd` | Create | Run timer state + player name, persists across scenes |
| `scripts/leaderboard.gd` | Create | dreamlo HTTP submit + fetch, emits `scores_received` |
| `scripts/game.gd` | Modify | Start timer on level 1, stop and store on win |
| `scripts/win.gd` | Modify | Display time, name entry, submit, show top 10 |
| `scenes/win.tscn` | Modify | Add time label, LineEdit, submit button, results label |
| `scripts/endless.gd` | Modify | Track max distance; show leaderboard overlay on exit |
| `scenes/endless.tscn` | Modify | Add hidden leaderboard overlay CanvasLayer |

---

## Task 1: GameSession Autoload

**Files:**
- Create: `scripts/game_session.gd`
- Modify: `project.godot`

- [ ] **Step 1: Create scripts/game_session.gd**

```gdscript
extends Node

var player_name: String = ""
var run_elapsed_ms: int = 0

var _start_ticks: int = 0
var _running: bool = false

func start_run() -> void:
	_start_ticks = Time.get_ticks_msec()
	_running = true

func stop_run() -> void:
	if not _running:
		return
	run_elapsed_ms = Time.get_ticks_msec() - _start_ticks
	_running = false

static func format_ms(ms: int) -> String:
	var total_s := ms / 1000
	var tenths := (ms % 1000) / 100
	var sec := total_s % 60
	var min := total_s / 60
	return "%d:%02d.%d" % [min, sec, tenths]
```

- [ ] **Step 2: Register in project.godot**

Open `project.godot`. Under `[autoload]`, append:

```
GameSession="*res://scripts/game_session.gd"
```

Full `[autoload]` block after edit:

```
[autoload]

DayNightManager="*res://scripts/day_night_manager.gd"
AudioManager="*res://scripts/audio_manager.gd"
GameSession="*res://scripts/game_session.gd"
```

- [ ] **Step 3: Verify autoload**

Open Godot. Project > Project Settings > Autoload tab. `GameSession` should appear in the list. No errors in Output.

- [ ] **Step 4: Commit**

```
git add scripts/game_session.gd project.godot
git commit -m "feat(session): add GameSession autoload for run timer and player name"
```

---

## Task 2: Leaderboard Autoload

**Files:**
- Create: `scripts/leaderboard.gd`
- Modify: `project.godot`

- [ ] **Step 1: Create scripts/leaderboard.gd**

Replace `YOUR_TIME_PRIVATE_KEY`, `YOUR_TIME_PUBLIC_KEY`, `YOUR_DIST_PRIVATE_KEY`, `YOUR_DIST_PUBLIC_KEY` with the four keys from your two dreamlo accounts.

```gdscript
extends Node

const _TIME_PRIV := "YOUR_TIME_PRIVATE_KEY"
const _TIME_PUB := "YOUR_TIME_PUBLIC_KEY"
const _DIST_PRIV := "YOUR_DIST_PRIVATE_KEY"
const _DIST_PUB := "YOUR_DIST_PUBLIC_KEY"

signal scores_received(board: String, entries: Array)

func submit(board: String, name: String, score: int) -> void:
	var priv := _TIME_PRIV if board == "time" else _DIST_PRIV
	var url := "https://dreamlo.com/lb/%s/add/%s/%d" % [priv, name.uri_encode(), score]
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, _b): http.queue_free())
	http.request(url)

func fetch(board: String, count: int) -> void:
	var pub := _TIME_PUB if board == "time" else _DIST_PUB
	var order := "pipe-asc" if board == "time" else "pipe"
	var url := "https://dreamlo.com/lb/%s/%s/%d" % [pub, order, count]
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, body):
		var text: String = body.get_string_from_utf8()
		var entries: Array = []
		for line in text.split("\n"):
			var parts := line.split("|")
			if parts.size() >= 2 and parts[0] != "":
				entries.append({"name": parts[0], "score": int(parts[1])})
		scores_received.emit(board, entries)
		http.queue_free()
	)
	http.request(url)
```

- [ ] **Step 2: Register in project.godot**

Under `[autoload]`, append `Leaderboard`:

```
[autoload]

DayNightManager="*res://scripts/day_night_manager.gd"
AudioManager="*res://scripts/audio_manager.gd"
GameSession="*res://scripts/game_session.gd"
Leaderboard="*res://scripts/leaderboard.gd"
```

- [ ] **Step 3: Verify autoload**

Project Settings > Autoload. `Leaderboard` appears. No errors.

- [ ] **Step 4: Commit**

```
git add scripts/leaderboard.gd project.godot
git commit -m "feat(leaderboard): add Leaderboard autoload wrapping dreamlo HTTP API"
```

---

## Task 3: Timer Integration in game.gd

**Files:**
- Modify: `scripts/game.gd`

The timer starts when level 1 loads and stops when the player completes level 5.

- [ ] **Step 1: Start timer on level 1**

In `scripts/game.gd`, find `load_level(index: int)`. Add the timer start at the top of the function:

```gdscript
func load_level(index: int) -> void:
	if index == 0:
		GameSession.start_run()

	for child in level_container.get_children():
		child.queue_free()
	# ... rest of function unchanged
```

- [ ] **Step 2: Stop timer on win**

Find `_on_level_complete`. Before `change_scene_to_file`, stop the run:

```gdscript
func _on_level_complete() -> void:
	current_level_index += 1
	if current_level_index >= LEVELS.size():
		GameSession.stop_run()
		get_tree().change_scene_to_file("res://scenes/win.tscn")
	else:
		load_level(current_level_index)
```

- [ ] **Step 3: Verify timer runs**

Add a temporary print to `win.gd._ready()`:

```gdscript
func _ready() -> void:
	print("run_elapsed_ms: ", GameSession.run_elapsed_ms)
	$VBoxContainer/BonusButton.pressed.connect(_on_bonus_pressed)
```

Play from level 1 to completion. Output should print a non-zero millisecond value. Remove the print after confirming.

- [ ] **Step 4: Commit**

```
git add scripts/game.gd
git commit -m "feat(timer): start run timer on level 1, stop on level 5 complete"
```

---

## Task 4: Win Screen - Time Display, Name Entry, Leaderboard

**Files:**
- Modify: `scenes/win.tscn`
- Modify: `scripts/win.gd`

### Step 1: Update win.tscn

- [ ] Open `scenes/win.tscn`. The existing `VBoxContainer` has: Title, Subtitle, Hint, BonusButton. Add the following nodes **after** the Subtitle node and **before** the Hint node. Append these lines to the tscn after the `[node name="Subtitle" ...]` block:

```
[node name="TimeLabel" type="Label" parent="VBoxContainer"]
layout_mode = 2
text = "Time: --:--.-"
horizontal_alignment = 1
theme_override_font_sizes/font_size = 22

[node name="NameEntry" type="LineEdit" parent="VBoxContainer"]
layout_mode = 2
placeholder_text = "Enter name (max 16 chars)"
max_length = 16
horizontal_alignment = 1
theme_override_font_sizes/font_size = 16

[node name="SubmitTimeButton" type="Button" parent="VBoxContainer"]
layout_mode = 2
text = "Submit Time"
horizontal_alignment = 1
theme_override_font_sizes/font_size = 14

[node name="LeaderboardLabel" type="Label" parent="VBoxContainer"]
layout_mode = 2
text = ""
horizontal_alignment = 1
theme_override_font_sizes/font_size = 13
```

Also bump `load_steps` from `2` to `2` (no change needed - no new ext_resource).

### Step 2: Update win.gd

- [ ] Replace the entire contents of `scripts/win.gd`:

```gdscript
extends Control

const RETURN_DELAY := 999.0

var _timer: float = 0.0
var _done: bool = false
var _submitted: bool = false

func _ready() -> void:
	$VBoxContainer/BonusButton.pressed.connect(_on_bonus_pressed)
	$VBoxContainer/SubmitTimeButton.pressed.connect(_on_submit_pressed)
	Leaderboard.scores_received.connect(_on_scores_received)

	var ms := GameSession.run_elapsed_ms
	$VBoxContainer/TimeLabel.text = "Time: " + GameSession.format_ms(ms)

	if GameSession.player_name != "":
		$VBoxContainer/NameEntry.text = GameSession.player_name

func _process(delta: float) -> void:
	if _done:
		return
	_timer += delta
	if Input.is_action_just_pressed("jump") and not $VBoxContainer/NameEntry.has_focus():
		_done = true
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_submit_pressed() -> void:
	if _submitted:
		return
	var name_val := $VBoxContainer/NameEntry.text.strip_edges()
	if name_val == "":
		return
	GameSession.player_name = name_val
	_submitted = true
	$VBoxContainer/SubmitTimeButton.disabled = true
	$VBoxContainer/LeaderboardLabel.text = "Submitting..."
	Leaderboard.submit("time", name_val, GameSession.run_elapsed_ms)
	Leaderboard.fetch("time", 10)

func _on_scores_received(board: String, entries: Array) -> void:
	if board != "time":
		return
	var lines := ["Top Times:"]
	for i in entries.size():
		var e: Dictionary = entries[i]
		lines.append("%d. %-16s %s" % [i + 1, e["name"], GameSession.format_ms(e["score"])])
	$VBoxContainer/LeaderboardLabel.text = "\n".join(lines)

func _on_bonus_pressed() -> void:
	if _done:
		return
	_done = true
	get_tree().change_scene_to_file("res://scenes/endless.tscn")
```

- [ ] **Step 3: Verify**

Beat level 5. Win screen should show your time (e.g. "Time: 1:42.3"). Enter a name and click Submit Time. After a moment the leaderboard label should show "Top Times:" followed by ranked entries.

- [ ] **Step 4: Commit**

```
git add scenes/win.tscn scripts/win.gd
git commit -m "feat(win): show completion time, name entry, and top-10 time leaderboard"
```

---

## Task 5: Endless - Max Distance Tracking and Exit Overlay

**Files:**
- Modify: `scripts/endless.gd`
- Modify: `scenes/endless.tscn`

### Step 1: Add overlay nodes to endless.tscn

- [ ] Open `scenes/endless.tscn`. Append the following after the `[node name="HintLabel" ...]` block:

```
[node name="ExitOverlay" type="CanvasLayer" parent="."]
visible = false

[node name="DimRect" type="ColorRect" parent="ExitOverlay"]
layout_mode = 0
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0, 0, 0, 0.7)

[node name="Panel" type="VBoxContainer" parent="ExitOverlay"]
layout_mode = 0
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -220.0
offset_top = -160.0
offset_right = 220.0
offset_bottom = 160.0
theme_override_constants/separation = 12

[node name="DistanceLabel" type="Label" parent="ExitOverlay/Panel"]
layout_mode = 2
text = "Best Distance: 0m"
horizontal_alignment = 1
theme_override_font_sizes/font_size = 22

[node name="NameEntry" type="LineEdit" parent="ExitOverlay/Panel"]
layout_mode = 2
placeholder_text = "Enter name (max 16 chars)"
max_length = 16
horizontal_alignment = 1
theme_override_font_sizes/font_size = 16

[node name="SubmitDistButton" type="Button" parent="ExitOverlay/Panel"]
layout_mode = 2
text = "Submit Score"
horizontal_alignment = 1
theme_override_font_sizes/font_size = 14

[node name="LeaderboardLabel" type="Label" parent="ExitOverlay/Panel"]
layout_mode = 2
text = ""
horizontal_alignment = 1
theme_override_font_sizes/font_size = 13

[node name="MenuButton" type="Button" parent="ExitOverlay/Panel"]
layout_mode = 2
text = "Return to Menu"
horizontal_alignment = 1
theme_override_font_sizes/font_size = 14
```

### Step 2: Update endless.gd

- [ ] Replace the entire contents of `scripts/endless.gd`:

```gdscript
extends Node2D

const CHUNK_WIDTH := 640.0
const SPAWN_LOOKAHEAD := 1280.0
const DESPAWN_BEHIND := 1280.0
const KILL_Y := 1400.0

const DAY_SKY_LAYERS = [
	"res://assets/sprites/backgrounds/sky_day_1.png",
	"res://assets/sprites/backgrounds/sky_day_2.png",
	"res://assets/sprites/backgrounds/sky_day_3.png",
	"res://assets/sprites/backgrounds/sky_day_4.png",
	"res://assets/sprites/backgrounds/sky_day_5.png",
]
const NIGHT_SKY_LAYERS = [
	"res://assets/sprites/backgrounds/sky_night_1.png",
	"res://assets/sprites/backgrounds/sky_night_2.png",
	"res://assets/sprites/backgrounds/sky_night_3.png",
	"res://assets/sprites/backgrounds/sky_night_4.png",
]

@onready var background: Node2D = $BackgroundLayer/Background
@onready var chunk_container: Node2D = $ChunkContainer
@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var score_label: Label = $UI/ScoreLabel
@onready var exit_overlay: CanvasLayer = $ExitOverlay
@onready var dist_label: Label = $ExitOverlay/Panel/DistanceLabel
@onready var name_entry: LineEdit = $ExitOverlay/Panel/NameEntry
@onready var submit_btn: Button = $ExitOverlay/Panel/SubmitDistButton
@onready var lb_label: Label = $ExitOverlay/Panel/LeaderboardLabel
@onready var menu_btn: Button = $ExitOverlay/Panel/MenuButton

var _rng := RandomNumberGenerator.new()
var _next_chunk_x := 0.0
var _entry_y := 400.0
var _last_safe_pos := Vector2(100.0, 360.0)
var _chunks: Array = []
var _done: bool = false
var _submitted: bool = false
var _best_distance: int = 0

func _ready() -> void:
	_rng.randomize()
	var day_layers: Array = DAY_SKY_LAYERS.map(func(p: String) -> Texture2D: return load(p))
	var night_layers: Array = NIGHT_SKY_LAYERS.map(func(p: String) -> Texture2D: return load(p))
	background.set_level_textures(day_layers, night_layers)
	DayNightManager.reset()
	AudioManager.play_music("day")

	_place_spawn_platform()
	while _next_chunk_x < SPAWN_LOOKAHEAD * 2.0:
		_spawn_chunk()

	camera.limit_left = -200
	camera.limit_right = 10000000
	player.reset()

	if GameSession.player_name != "":
		name_entry.text = GameSession.player_name

	submit_btn.pressed.connect(_on_submit_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	Leaderboard.scores_received.connect(_on_scores_received)

func _process(_delta: float) -> void:
	if _done:
		return

	if exit_overlay.visible:
		return

	if player.is_on_floor():
		_last_safe_pos = player.global_position

	if player.global_position.y > KILL_Y:
		player.global_position = _last_safe_pos
		player.reset()

	while _next_chunk_x < player.global_position.x + SPAWN_LOOKAHEAD:
		_spawn_chunk()

	_despawn_old_chunks()

	camera.limit_left = int(player.global_position.x) - 400

	var dist := int(player.global_position.x / 50.0)
	if dist > _best_distance:
		_best_distance = dist
	score_label.text = "Distance: " + str(dist) + "m"

	if Input.is_action_just_pressed("ui_cancel"):
		_show_exit_overlay()

func _show_exit_overlay() -> void:
	dist_label.text = "Best Distance: " + str(_best_distance) + "m"
	exit_overlay.visible = true
	name_entry.grab_focus()

func _on_submit_pressed() -> void:
	if _submitted:
		return
	var name_val := name_entry.text.strip_edges()
	if name_val == "":
		return
	GameSession.player_name = name_val
	_submitted = true
	submit_btn.disabled = true
	lb_label.text = "Submitting..."
	Leaderboard.submit("distance", name_val, _best_distance)
	Leaderboard.fetch("distance", 10)

func _on_scores_received(board: String, entries: Array) -> void:
	if board != "distance":
		return
	var lines := ["Top Distances:"]
	for i in entries.size():
		var e: Dictionary = entries[i]
		lines.append("%d. %-16s %dm" % [i + 1, e["name"], e["score"]])
	lb_label.text = "\n".join(lines)

func _on_menu_pressed() -> void:
	_done = true
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _place_spawn_platform() -> void:
	var body := StaticBody2D.new()
	body.set_script(load("res://scripts/platform.gd"))
	body.set("platform_type", 0)
	var cshape := CollisionShape2D.new()
	cshape.name = "CollisionShape2D"
	var rect := RectangleShape2D.new()
	rect.size = Vector2(300.0, 16.0)
	cshape.shape = rect
	body.add_child(cshape)
	var spr := Sprite2D.new()
	spr.name = "Sprite2D"
	body.add_child(spr)
	body.position = Vector2(150.0, 400.0)
	chunk_container.add_child(body)

func _spawn_chunk() -> void:
	var chunk := Node2D.new()
	chunk.set_script(load("res://scripts/endless_chunk.gd"))
	chunk.position.x = _next_chunk_x
	chunk_container.add_child(chunk)
	_entry_y = chunk.generate(_rng, _entry_y)
	_chunks.append(chunk)
	_next_chunk_x += CHUNK_WIDTH

func _despawn_old_chunks() -> void:
	var cutoff := player.global_position.x - DESPAWN_BEHIND
	var i := 0
	while i < _chunks.size():
		var c: Node2D = _chunks[i]
		if c.position.x + CHUNK_WIDTH < cutoff:
			c.queue_free()
			_chunks.remove_at(i)
		else:
			i += 1
```

- [ ] **Step 3: Verify**

Run endless scene. Play to some distance. Press Escape. Overlay should appear with your best distance, a name entry field, Submit Score, and Return to Menu buttons. Submitting sends your score to dreamlo and fetches the top 10.

- [ ] **Step 4: Commit**

```
git add scenes/endless.tscn scripts/endless.gd
git commit -m "feat(endless): max distance tracking, exit overlay, distance leaderboard"
```

---

## Task 6: End-to-End Verification

- [ ] **Full main game run:** Play from main menu through all 5 levels. Win screen shows accurate time. Submit a name. Top-10 refreshes with your entry.

- [ ] **Timer resets on replay:** Return to menu, start again. Win screen shows a new (independent) time. The previous time is not reused.

- [ ] **Player name persists:** Name entered on win screen pre-fills the endless exit overlay (and vice versa), since both read/write `GameSession.player_name`.

- [ ] **Offline graceful:** Disable network (or use wrong dreamlo keys). Game still runs normally - submit silently fails, leaderboard label stays at "Submitting..." or blank. No crash.

- [ ] **Commit**

```
git add .
git commit -m "feat(leaderboard): end-to-end verification complete"
```

---

## Self-Review

**Spec coverage:**
- Global leaderboard for bonus level distance: Task 5 - submits `_best_distance` on exit, fetches top 10
- Global timer for 5 levels: Tasks 1+3 - `GameSession.start_run()` on level 0, `stop_run()` before win scene
- Timer displayed on win screen: Task 4 - `TimeLabel` shows `format_ms(run_elapsed_ms)`
- Score submission on win: Task 4 - SubmitTimeButton calls `Leaderboard.submit("time", ...)`

**Placeholder scan:** None found.

**Type consistency:**
- `Leaderboard.submit(board: String, name: String, score: int)` - called in win.gd as `submit("time", name_val, GameSession.run_elapsed_ms)` - `run_elapsed_ms` is `int`, matches
- `Leaderboard.submit` in endless.gd as `submit("distance", name_val, _best_distance)` - `_best_distance` is `int`, matches
- `Leaderboard.scores_received(board: String, entries: Array)` - connected in both win.gd and endless.gd; each filters by board name to avoid cross-contamination
- `GameSession.format_ms(ms: int) -> String` - called as `GameSession.format_ms(e["score"])` in win.gd where `e["score"]` is `int(parts[1])` - consistent
