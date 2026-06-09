# Bonus Endless Level Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an endless procedurally generated platformer accessible from the win screen, where the player jumps across auto-spawned platform chunks scrolling rightward forever.

**Architecture:** Chunk-based generation - fixed-width (640px) Node2D chunks spawn ahead of the player and despawn when far behind the camera. `endless.gd` manages spawn/despawn, score, fall-respawn, and camera drift. `endless_chunk.gd` builds one chunk's platforms procedurally using the existing `platform.gd` script (which already handles day/night visibility). `win.gd` gains a Bonus button that routes to the new scene.

**Tech Stack:** Godot 4.3+ GDScript. Reuses `player.gd`, `platform.gd`, `background.gd`, `DayNightManager` autoload, `AudioManager` autoload - all unchanged.

**No timer:** `endless.tscn` has no `DuskTimer` node. `endless.gd` never connects to `DayNightManager.toggled`. Day/night toggle costs nothing and has no countdown - toggle freely.

---

## Player Jump Physics Reference

Before touching generation params, know what the player can do:

| Constant | Value |
|----------|-------|
| SPEED | 200 px/s |
| JUMP_VELOCITY | -580 px/s |
| GRAVITY | 980 px/s^2 |
| DASH_SPEED | 600 px/s |
| DASH_DURATION | 0.15 s |

- Max jump height: `580^2 / (2 * 980)` = **171 px**
- Full air time: `2 * 580 / 980` = **1.18 s**
- Horizontal range at walk: `200 * 1.18` = **236 px**

Safe gap budget (no dash required): **160 px horizontal, 120 px vertical**.

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `scenes/win.tscn` | Modify | Add BonusButton node |
| `scripts/win.gd` | Modify | Handle bonus button -> load endless scene |
| `scenes/endless.tscn` | Create | Root scene: player, background, chunk container, UI |
| `scripts/endless.gd` | Create | Chunk manager, score display, fall-respawn, camera drift |
| `scripts/endless_chunk.gd` | Create | Builds one 640px chunk with 3-5 platforms |

---

## Task 1: Add Bonus Button to Win Screen

**Files:**
- Modify: `scenes/win.tscn`
- Modify: `scripts/win.gd`

- [ ] **Step 1: Add BonusButton to win.tscn**

Open `scenes/win.tscn`. After the `[node name="Hint" ...]` block, append:

```
[node name="BonusButton" type="Button" parent="VBoxContainer"]
layout_mode = 2
text = "Play Bonus Level"
horizontal_alignment = 1
theme_override_font_sizes/font_size = 14
```

- [ ] **Step 2: Update win.gd**

Replace the entire contents of `scripts/win.gd`:

```gdscript
extends Control

const RETURN_DELAY := 6.0

var _timer: float = 0.0
var _done: bool = false

func _ready() -> void:
	$VBoxContainer/BonusButton.pressed.connect(_on_bonus_pressed)

func _process(delta: float) -> void:
	if _done:
		return
	_timer += delta
	if _timer >= RETURN_DELAY or Input.is_action_just_pressed("jump"):
		_done = true
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_bonus_pressed() -> void:
	if _done:
		return
	_done = true
	get_tree().change_scene_to_file("res://scenes/endless.tscn")
```

- [ ] **Step 3: Verify in Godot**

Open Godot. Play from `scenes/win.tscn` directly (Scene > Open Scene, then F6). Confirm the "Play Bonus Level" button appears below the hint text. Clicking it should fail gracefully (scene does not exist yet) or show an error - that is expected at this step.

- [ ] **Step 4: Commit**

```
git add scenes/win.tscn scripts/win.gd
git commit -m "feat(win): add bonus level button"
```

---

## Task 2: Create endless.tscn

**Files:**
- Create: `scenes/endless.tscn`

- [ ] **Step 1: Create the scene file**

Create `scenes/endless.tscn` with the following content exactly:

```
[gd_scene load_steps=5 format=3 uid="uid://solstice_endless"]

[ext_resource type="Script" path="res://scripts/endless.gd" id="1_end"]
[ext_resource type="Script" path="res://scripts/player.gd" id="2_plyr"]
[ext_resource type="Script" path="res://scripts/background.gd" id="3_bg"]

[sub_resource type="CapsuleShape2D" id="CS_player"]
radius = 16.0
height = 64.0

[node name="Endless" type="Node2D"]
script = ExtResource("1_end")

[node name="BackgroundLayer" type="CanvasLayer" parent="."]
layer = -1

[node name="Background" type="Node2D" parent="BackgroundLayer"]
script = ExtResource("3_bg")

[node name="ChunkContainer" type="Node2D" parent="."]

[node name="Player" type="CharacterBody2D" parent="." groups=["player"]]
position = Vector2(100, 360)
script = ExtResource("2_plyr")

[node name="CollisionShape2D" type="CollisionShape2D" parent="Player"]
shape = SubResource("CS_player")

[node name="Sprite2D" type="Sprite2D" parent="Player"]

[node name="Camera2D" type="Camera2D" parent="Player"]
position_smoothing_enabled = true
position_smoothing_speed = 5.0

[node name="UI" type="CanvasLayer" parent="."]

[node name="ScoreLabel" type="Label" parent="UI"]
offset_left = 8.0
offset_top = 8.0
offset_right = 300.0
offset_bottom = 36.0
text = "Distance: 0m"
theme_override_font_sizes/font_size = 20

[node name="HintLabel" type="Label" parent="UI"]
anchor_right = 1.0
offset_top = 8.0
offset_bottom = 36.0
horizontal_alignment = 2
text = "Esc - Menu"
theme_override_font_sizes/font_size = 14
```

- [ ] **Step 2: Verify scene loads**

In Godot, File > Open `scenes/endless.tscn`. The scene tree should show: Endless > BackgroundLayer/Background, ChunkContainer, Player (with CollisionShape2D, Sprite2D, Camera2D), UI (with ScoreLabel, HintLabel). No parse errors in the Output panel.

- [ ] **Step 3: Commit**

```
git add scenes/endless.tscn
git commit -m "feat(endless): add scene skeleton"
```

---

## Task 3: Implement endless_chunk.gd

**Files:**
- Create: `scripts/endless_chunk.gd`

One chunk is a `Node2D` that holds 3-5 `StaticBody2D` platforms. It calls `generate()` once, which places platforms using a `RandomNumberGenerator` passed from the parent so seeds are reproducible. Returns the exit Y so the next chunk starts at a reachable height.

- [ ] **Step 1: Create scripts/endless_chunk.gd**

```gdscript
extends Node2D

const CHUNK_WIDTH := 640.0
const PLATFORM_H := 16.0
const MIN_PLATFORM_W := 80.0
const MAX_PLATFORM_W := 200.0
const MIN_GAP := 60.0
const MAX_GAP := 160.0
const MAX_DELTA_Y := 100.0
const Y_MIN := 180.0
const Y_MAX := 580.0

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
```

- [ ] **Step 2: Verify parse**

In Godot, in the Script editor open `scripts/endless_chunk.gd`. Check that no syntax errors appear in the Output panel. You can also run `gdscript --check scripts/endless_chunk.gd` from terminal if Godot CLI is available; errors print to stdout.

- [ ] **Step 3: Commit**

```
git add scripts/endless_chunk.gd
git commit -m "feat(endless): add chunk procedural generation"
```

---

## Task 4: Implement endless.gd

**Files:**
- Create: `scripts/endless.gd`

This is the main manager. It:
- Spawns initial chunks on `_ready`
- Spawns new chunks when the player approaches the right edge
- Despawns chunks that are more than 1280px behind the player
- Tracks the last safe position for fall-respawn
- Displays distance score
- Handles Escape -> main menu
- Drifts `camera.limit_left` rightward to prevent backtracking

- [ ] **Step 1: Create scripts/endless.gd**

```gdscript
extends Node2D

const ChunkScene := preload("res://scripts/endless_chunk.gd")
const CHUNK_WIDTH := 640.0
const SPAWN_LOOKAHEAD := 1280.0
const DESPAWN_BEHIND := 1280.0
const KILL_Y := 800.0

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

var _rng := RandomNumberGenerator.new()
var _next_chunk_x := 0.0
var _entry_y := 360.0
var _last_safe_pos := Vector2(100.0, 360.0)
var _chunks: Array = []
var _done: bool = false

func _ready() -> void:
	_rng.randomize()
	var day_layers: Array = DAY_SKY_LAYERS.map(func(p: String) -> Texture2D: return load(p))
	var night_layers: Array = NIGHT_SKY_LAYERS.map(func(p: String) -> Texture2D: return load(p))
	background.set_level_textures(day_layers, night_layers)
	DayNightManager.reset()
	AudioManager.play_music("day")

	_spawn_floor()
	while _next_chunk_x < SPAWN_LOOKAHEAD * 2.0:
		_spawn_chunk()

	camera.limit_left = -200
	camera.limit_top = 0
	camera.limit_bottom = 720
	camera.limit_right = 10000000
	player.reset()

func _process(delta: float) -> void:
	if _done:
		return

	if Input.is_action_just_pressed("ui_cancel"):
		_done = true
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
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
	score_label.text = "Distance: " + str(dist) + "m"

func _spawn_floor() -> void:
	var body := StaticBody2D.new()
	var cshape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10000.0, 32.0)
	cshape.shape = rect
	body.add_child(cshape)
	body.position = Vector2(5000.0, 650.0)
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

- [ ] **Step 2: Verify parse**

Open `scripts/endless.gd` in Godot Script editor. No red errors in Output.

- [ ] **Step 3: Verify initial load**

Press F5 to run from the project's main scene, then navigate to the win screen and click "Play Bonus Level" - OR temporarily set endless.tscn as the main scene (Project > Project Settings > Application > Run > Main Scene = `res://scenes/endless.tscn`). The player should spawn at (100, 360) on a platform, with a pink sky background and "Distance: 0m" in the top-left. Moving right should reveal new platforms generating ahead.

Expected issues at this step: `endless_chunk.gd` is loaded via `set_script()` but the scene file does NOT use it as an `ext_resource`. This is correct - `endless_chunk.gd` is loaded at runtime, not declared in the `.tscn` file.

- [ ] **Step 4: Commit**

```
git add scripts/endless.gd
git commit -m "feat(endless): add chunk manager and score display"
```

---

## Task 5: Fix chunk script loading and verify full flow

Godot's `set_script()` on a newly created Node2D requires the script to be a `GDScript` resource, not a plain `Node2D` script with `extends Node2D`. The `endless.gd` uses `chunk.set_script(load("res://scripts/endless_chunk.gd"))`. Verify this works and fix if not.

**Files:**
- Modify: `scripts/endless.gd` (if needed)
- Modify: `scripts/endless_chunk.gd` (if needed)

- [ ] **Step 1: Test chunk spawning**

Run the endless scene. Open the Remote Scene Tree (Scene > Remote > select Endless). Expand `ChunkContainer`. You should see multiple `Node2D` children each containing `StaticBody2D` platform nodes.

If the chunk container is empty (chunks not spawning), the `set_script` / `generate` call is failing silently. Add a print statement to `endless.gd._spawn_chunk()` temporarily:

```gdscript
func _spawn_chunk() -> void:
	var chunk := Node2D.new()
	chunk.set_script(load("res://scripts/endless_chunk.gd"))
	chunk.position.x = _next_chunk_x
	chunk_container.add_child(chunk)
	print("chunk script: ", chunk.get_script())
	_entry_y = chunk.generate(_rng, _entry_y)
	print("spawned chunk at x=", _next_chunk_x, " entry_y=", _entry_y)
	_chunks.append(chunk)
	_next_chunk_x += CHUNK_WIDTH
```

Check Output for prints. If `chunk.get_script()` prints `null`, the load path is wrong.

- [ ] **Step 2: Test day/night toggle**

While running, press E to toggle. Platforms with `platform_type=1` (DAY_ONLY, gold color) should disappear. Platforms with `platform_type=2` (SHADOW_ONLY, purple color) should appear. Background switches from pink day sky to night sky. Press E again to return to day.

- [ ] **Step 3: Test fall-respawn**

Walk off the right edge of a platform and fall below y=800. Player should teleport back to the last on-floor position without freezing or crashing.

- [ ] **Step 4: Test Escape key**

Press Escape. Should return to main menu scene.

- [ ] **Step 5: Test win screen flow**

Run from main scene (F5). Complete all 5 levels (or temporarily set `current_level_index` to 4 in game.gd and exit the last level). Win screen appears. Click "Play Bonus Level". Endless scene loads. Press Space on win screen - goes to main menu (original behavior preserved).

- [ ] **Step 6: Remove debug prints**

Remove the `print()` statements added in Step 1 if any.

- [ ] **Step 7: Commit**

```
git add scripts/endless.gd scripts/endless_chunk.gd
git commit -m "feat(endless): verify and fix chunk spawn flow"
```

---

## Task 6: Polish - starting platform and camera feel

The player spawns at (100, 360) but there is no guaranteed platform under them at start. A dedicated spawn platform ensures they don't immediately fall.

**Files:**
- Modify: `scripts/endless.gd`

- [ ] **Step 1: Add spawn platform**

In `endless.gd._ready()`, after `_spawn_floor()` and before the chunk-spawn loop, add:

```gdscript
	_place_spawn_platform()
```

Add the method:

```gdscript
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
```

Also set `_entry_y = 400.0` (matches spawn platform Y) before the chunk loop so first chunk generates platforms reachable from that height. Replace the chunk loop init in `_ready()`:

```gdscript
	_entry_y = 400.0
	while _next_chunk_x < SPAWN_LOOKAHEAD * 2.0:
		_spawn_chunk()
```

- [ ] **Step 2: Verify player lands on spawn platform**

Run endless scene. Player should land on the wide solid platform at x=0-300, y=400 immediately on spawn without falling.

- [ ] **Step 3: Commit**

```
git add scripts/endless.gd
git commit -m "feat(endless): add guaranteed spawn platform"
```

---

## Self-Review Checklist

**Spec coverage:**
- Accessible from win screen: Task 1
- Endless (never ends): Tasks 4, 5 - chunks spawn indefinitely, no win condition
- Procedurally generated: Task 3 - random platform positions, widths, types per chunk
- Vertical/horizontal scroller: Camera2D follows player in both X and Y; platforms span multiple heights (180-580px range)
- Day/night mechanic preserved: Tasks 4, 5 - DayNightManager active, platform types 1 and 2 react to toggle, background switches

**Potential gaps:**
- No high-score persistence (out of scope for game jam)
- No explicit "infinite lives" message to player - the hint label covers Escape only; fall-respawn is silent which is fine
- Floor at y=650 in `_spawn_floor()` catches edge cases but is not visible; acceptable

**Type consistency check:**
- `endless_chunk.gd`: `generate(rng: RandomNumberGenerator, entry_y: float) -> float` - called correctly in `endless.gd._spawn_chunk()` as `chunk.generate(_rng, _entry_y)` - matches
- `background.set_level_textures(day_layers: Array, night_layers: Array)` - called with two Arrays in `endless.gd._ready()` - matches
- `_chunks: Array` stores `Node2D` instances, accessed as `Node2D` in `_despawn_old_chunks()` - consistent
