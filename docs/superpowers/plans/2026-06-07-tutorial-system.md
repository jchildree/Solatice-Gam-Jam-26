# Tutorial System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a sequential button-prompt tutorial before level 1 that pauses the dusk timer and advances one step per correct input.

**Architecture:** New `scenes/tutorial.tscn` scene with a dedicated `scripts/tutorial.gd` controller. Main menu routes to tutorial instead of game. On completing all four prompts, tutorial loads `game.tscn`. DuskTimer node is present but never started, keeping the bar frozen.

**Tech Stack:** Godot 4, GDScript

---

## File Map

- Create: `scripts/tutorial.gd`
- Create: `scenes/tutorial.tscn`
- Modify: `scripts/main_menu.gd` -- route Play to tutorial

---

### Task 1: Write tutorial.gd

**Files:**
- Create: `scripts/tutorial.gd`

- [ ] **Step 1: Create scripts/tutorial.gd**

```gdscript
extends Node2D

const STEPS = [
	{ "actions": ["move_left", "move_right"], "prompt": "Press A or D to move" },
	{ "actions": ["jump"], "prompt": "Press Space to jump" },
	{ "actions": ["dash"], "prompt": "Press Shift to dash" },
	{ "actions": ["toggle"], "prompt": "Press E to toggle day and night" },
]

var current_step: int = 0

@onready var prompt_label: Label = $UI/PromptLabel

func _ready() -> void:
	_show_step(0)

func _process(_delta: float) -> void:
	if current_step >= STEPS.size():
		return
	for action in STEPS[current_step]["actions"]:
		if Input.is_action_just_pressed(action):
			_advance()
			return

func _advance() -> void:
	current_step += 1
	if current_step >= STEPS.size():
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	else:
		_show_step(current_step)

func _show_step(index: int) -> void:
	prompt_label.text = STEPS[index]["prompt"]
```

- [ ] **Step 2: Verify in Godot editor**

Open Godot. In the FileSystem dock, confirm `scripts/tutorial.gd` appears. Click it -- no red parse errors in the Script editor status bar.

- [ ] **Step 3: Commit**

```bash
git add scripts/tutorial.gd
git commit -m "feat(tutorial): add tutorial controller script"
```

---

### Task 2: Create tutorial.tscn

**Files:**
- Create: `scenes/tutorial.tscn`

The scene needs: root Node2D with tutorial.gd, a Background, a floor StaticBody2D, the Player (reusing player.gd), a DuskTimer node (never started), and a CanvasLayer UI with a centered Label.

- [ ] **Step 1: Create scenes/tutorial.tscn**

```
[gd_scene load_steps=6 format=3 uid="uid://tutorial01"]

[ext_resource type="Script" path="res://scripts/tutorial.gd" id="1_tut"]
[ext_resource type="Script" path="res://scripts/player.gd" id="2_plyr"]
[ext_resource type="Script" path="res://scripts/dusk_timer.gd" id="3_dusk"]
[ext_resource type="Script" path="res://scripts/background.gd" id="4_bg"]
[ext_resource type="Texture2D" path="res://assets/sprites/stickman.svg" id="5_spr"]

[sub_resource type="CapsuleShape2D" id="CS_player"]
radius = 10.0
height = 48.0

[sub_resource type="RectangleShape2D" id="RS_floor"]
size = Vector2(1280.0, 32.0)

[node name="Tutorial" type="Node2D"]
script = ExtResource("1_tut")

[node name="Background" type="Sprite2D" parent="."]
script = ExtResource("4_bg")
position = Vector2(0, 0)
centered = false
z_index = -10

[node name="Floor" type="StaticBody2D" parent="."]
position = Vector2(640, 400)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Floor"]
shape = SubResource("RS_floor")

[node name="Player" type="CharacterBody2D" parent="." groups=["player"]]
position = Vector2(200, 340)
script = ExtResource("2_plyr")

[node name="CollisionShape2D" type="CollisionShape2D" parent="Player"]
shape = SubResource("CS_player")

[node name="Sprite2D" type="Sprite2D" parent="Player"]
texture = ExtResource("5_spr")

[node name="DuskTimer" type="Node" parent="." groups=["dusk_timer"]]
script = ExtResource("3_dusk")

[node name="UI" type="CanvasLayer" parent="."]

[node name="PromptLabel" type="Label" parent="UI"]
anchor_left = 0.5
anchor_right = 0.5
anchor_top = 0.75
anchor_bottom = 0.75
offset_left = -300.0
offset_right = 300.0
offset_top = -24.0
offset_bottom = 24.0
horizontal_alignment = 1
theme_override_font_sizes/font_size = 24
```

- [ ] **Step 2: Open in Godot editor and verify**

In Godot, double-click `scenes/tutorial.tscn`. Confirm:
- Scene tree shows Tutorial > Background, Floor, Player, DuskTimer, UI > PromptLabel
- No errors in Output panel
- Player node has `player` group set (check Node tab > Groups)
- DuskTimer node has `dusk_timer` group set

If `background.gd` errors (it may reference DayNightManager which is an autoload -- that is fine), check Output for any `ERROR` lines and fix before continuing.

- [ ] **Step 3: Commit**

```bash
git add scenes/tutorial.tscn
git commit -m "feat(tutorial): add tutorial scene with player and floor"
```

---

### Task 3: Route main menu to tutorial

**Files:**
- Modify: `scripts/main_menu.gd`

- [ ] **Step 1: Change scene target in main_menu.gd**

Current content of `scripts/main_menu.gd`:

```gdscript
extends Control

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
```

Replace with:

```gdscript
extends Control

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/tutorial.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
```

- [ ] **Step 2: Verify flow in Godot**

Run the game (F5). Click Play on main menu. Confirm:
1. Tutorial scene loads -- player visible on floor, prompt label shows "Press A or D to move"
2. Press D -- prompt changes to "Press Space to jump"
3. Press Space -- prompt changes to "Press Shift to dash"
4. Press Shift -- prompt changes to "Press E to toggle day and night"
5. Press E -- game.tscn loads, level 1 starts, dusk timer begins counting
6. During tutorial: dusk timer bar is frozen (DuskTimer was never started)

- [ ] **Step 3: Commit**

```bash
git add scripts/main_menu.gd
git commit -m "feat(tutorial): route main menu through tutorial before level 1"
```
