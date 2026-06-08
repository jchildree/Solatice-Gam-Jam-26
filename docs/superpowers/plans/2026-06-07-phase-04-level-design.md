# Phase 04 - Level Design Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a scrolling camera and redesign levels 3-5 to use horizontal, vertical, and combined scrolling layouts.

**Architecture:** A Camera2D attached to Player follows the player through the world. game.gd applies per-level Camera2D limits from a LEVEL_BOUNDS constant. The Background Sprite2D moves to a CanvasLayer so it stays fixed to the viewport during scrolling. Levels 3-5 are replaced with larger layouts matching their scroll axis.

**Tech Stack:** Godot 4 GDScript, Camera2D, CanvasLayer, CharacterBody2D

---

## File Map

| File | Change |
|------|--------|
| `scenes/game.tscn` | Add Camera2D to Player; move Background into CanvasLayer |
| `scripts/game.gd` | Add LEVEL_BOUNDS constant; apply camera limits in load_level() |
| `scenes/levels/level_3.tscn` | Full replace - horizontal scroll, 2560x720 |
| `scenes/levels/level_4.tscn` | Full replace - vertical scroll, 1280x1440 |
| `scenes/levels/level_5.tscn` | Full replace - combined scroll, 2560x1440 |

---

### Task 1: Add Camera2D to Player and fix Background scrolling in game.tscn

**Files:**
- Modify: `scenes/game.tscn`

The Background Sprite2D is currently a direct child of the Game Node2D. When Camera2D scrolls, the background scrolls with the world and reveals empty space. Moving it to a CanvasLayer (layer = -1) pins it to the viewport.

- [ ] **Step 1: Replace the Background and LevelContainer section of game.tscn**

Open `scenes/game.tscn`. The current file reads:

```
[node name="Background" type="Sprite2D" parent="."]
script = ExtResource("6_bg01")
position = Vector2(0, 0)
centered = false
z_index = -10

[node name="LevelContainer" type="Node2D" parent="."]
```

Replace with:

```
[node name="BackgroundLayer" type="CanvasLayer" parent="."]
layer = -1

[node name="Background" type="Sprite2D" parent="BackgroundLayer"]
script = ExtResource("6_bg01")
position = Vector2(0, 0)
centered = false

[node name="LevelContainer" type="Node2D" parent="."]
```

- [ ] **Step 2: Add Camera2D as child of Player**

After the existing `[node name="Sprite2D" ...]` entry under Player, append:

```
[node name="Camera2D" type="Camera2D" parent="Player"]
position_smoothing_enabled = true
position_smoothing_speed = 5.0
```

- [ ] **Step 3: Run game in Godot (F5), verify background stays fixed**

Expected: background fills viewport and does not shift when player moves. No console errors.

- [ ] **Step 4: Commit**

```
git add scenes/game.tscn
git commit -m "feat(camera): add Camera2D to player, pin background to CanvasLayer"
```

---

### Task 2: Add LEVEL_BOUNDS and apply camera limits in game.gd

**Files:**
- Modify: `scripts/game.gd`

Camera2D defaults to unlimited scroll. Without per-level limits the camera shows empty space outside the level. LEVEL_BOUNDS constrains Camera2D per level.

- [ ] **Step 1: Add LEVEL_BOUNDS constant and camera onready**

In `scripts/game.gd`, after the existing `const LEVEL_BUDGETS` line, add:

```gdscript
const LEVEL_BOUNDS = [
    Rect2(0, 0, 1280, 720),
    Rect2(0, 0, 1280, 720),
    Rect2(0, 0, 2560, 720),
    Rect2(0, 0, 1280, 1440),
    Rect2(0, 0, 2560, 1440),
]
```

After the existing `@onready var dusk_timer` line, add:

```gdscript
@onready var camera: Camera2D = $Player/Camera2D
```

- [ ] **Step 2: Apply limits in load_level()**

Inside `load_level(index: int)`, after `player.reset()`, add:

```gdscript
var b: Rect2 = LEVEL_BOUNDS[index]
camera.limit_left = int(b.position.x)
camera.limit_top = int(b.position.y)
camera.limit_right = int(b.position.x + b.size.x)
camera.limit_bottom = int(b.position.y + b.size.y)
```

- [ ] **Step 3: Run game (F5), play level 1**

Expected: camera follows player, stops at edges of 1280x720, no empty space visible. Level 2 behaves identically.

- [ ] **Step 4: Commit**

```
git add scripts/game.gd
git commit -m "feat(camera): apply per-level Camera2D bounds from LEVEL_BOUNDS"
```

---

### Task 3: Redesign level_3.tscn - Horizontal scroll (2560x720)

*Like Nana following Satoru west across Japan, the player traces a long rightward path with no way back.*

**Files:**
- Modify: `scenes/levels/level_3.tscn` (full replace)

Layout: ground spans 2560px. Platforms climb gently right-to-left. DAY/SHADOW platforms alternate to force toggling. One checkpoint at the horizontal midpoint.

- [ ] **Step 1: Replace level_3.tscn entirely**

Write the following as the complete file content:

```
[gd_scene load_steps=6 format=3 uid="uid://solstice_lvl3"]

[ext_resource type="PackedScene" path="res://scenes/objects/platform.tscn" id="1_plat"]
[ext_resource type="PackedScene" path="res://scenes/objects/exit_portal.tscn" id="2_exit"]
[ext_resource type="PackedScene" path="res://scenes/objects/checkpoint.tscn" id="3_chk"]

[sub_resource type="RectangleShape2D" id="RS_ground"]
size = Vector2(2560, 32)

[sub_resource type="CircleShape2D" id="CS_exit"]
radius = 24.0

[sub_resource type="CircleShape2D" id="CS_chk"]
radius = 20.0

[node name="Level3" type="Node2D"]

[node name="StartPosition" type="Marker2D" parent="."]
position = Vector2(100, 580)

[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(1280, 700)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]
shape = SubResource("RS_ground")

[node name="ShadowPlatform1" parent="." instance=ExtResource("1_plat")]
position = Vector2(220, 570)
platform_type = 2

[node name="DayPlatform1" parent="." instance=ExtResource("1_plat")]
position = Vector2(420, 530)
platform_type = 1

[node name="ShadowPlatform2" parent="." instance=ExtResource("1_plat")]
position = Vector2(640, 490)
platform_type = 2

[node name="DayPlatform2" parent="." instance=ExtResource("1_plat")]
position = Vector2(860, 450)
platform_type = 1

[node name="SolidPlatform1" parent="." instance=ExtResource("1_plat")]
position = Vector2(1060, 410)
platform_type = 0

[node name="Checkpoint1" parent="." instance=ExtResource("3_chk")]
position = Vector2(1060, 380)
saved_time = 36.0

[node name="CollisionShape2D" type="CollisionShape2D" parent="Checkpoint1"]
shape = SubResource("CS_chk")

[node name="DayPlatform3" parent="." instance=ExtResource("1_plat")]
position = Vector2(1260, 390)
platform_type = 1

[node name="ShadowPlatform3" parent="." instance=ExtResource("1_plat")]
position = Vector2(1460, 360)
platform_type = 2

[node name="DayPlatform4" parent="." instance=ExtResource("1_plat")]
position = Vector2(1660, 330)
platform_type = 1

[node name="ShadowPlatform4" parent="." instance=ExtResource("1_plat")]
position = Vector2(1860, 300)
platform_type = 2

[node name="SolidPlatform2" parent="." instance=ExtResource("1_plat")]
position = Vector2(2060, 270)
platform_type = 0

[node name="DayPlatform5" parent="." instance=ExtResource("1_plat")]
position = Vector2(2260, 240)
platform_type = 1

[node name="ExitPortal" parent="." instance=ExtResource("2_exit")]
position = Vector2(2400, 200)

[node name="CollisionShape2D" type="CollisionShape2D" parent="ExitPortal"]
shape = SubResource("CS_exit")
```

- [ ] **Step 2: Run game (F5), skip to level 3 via main menu or temporarily set `current_level_index = 2` in game.gd**

Expected: camera starts left, follows player rightward, stops scrolling at x=2560 boundary. ShadowPlatform1 is invisible in day state; DayPlatform1 is invisible in night state. Level is completable.

- [ ] **Step 3: Restore `current_level_index = 0` if changed**

- [ ] **Step 4: Commit**

```
git add scenes/levels/level_3.tscn
git commit -m "feat(level3): redesign as horizontal scroll layout, 2560px wide"
```

---

### Task 4: Redesign level_4.tscn - Vertical scroll (1280x1440)

**Files:**
- Modify: `scenes/levels/level_4.tscn` (full replace)

Layout: ground at y=1440. Player starts at bottom and climbs to exit at top. Platforms zigzag left-right to require both movement and toggling. One checkpoint at midheight.

- [ ] **Step 1: Replace level_4.tscn entirely**

```
[gd_scene load_steps=6 format=3 uid="uid://solstice_lvl4"]

[ext_resource type="PackedScene" path="res://scenes/objects/platform.tscn" id="1_plat"]
[ext_resource type="PackedScene" path="res://scenes/objects/exit_portal.tscn" id="2_exit"]
[ext_resource type="PackedScene" path="res://scenes/objects/checkpoint.tscn" id="3_chk"]

[sub_resource type="RectangleShape2D" id="RS_ground"]
size = Vector2(1280, 32)

[sub_resource type="CircleShape2D" id="CS_exit"]
radius = 24.0

[sub_resource type="CircleShape2D" id="CS_chk"]
radius = 20.0

[node name="Level4" type="Node2D"]

[node name="StartPosition" type="Marker2D" parent="."]
position = Vector2(400, 1360)

[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(640, 1440)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]
shape = SubResource("RS_ground")

[node name="ShadowPlatform1" parent="." instance=ExtResource("1_plat")]
position = Vector2(200, 1260)
platform_type = 2

[node name="DayPlatform1" parent="." instance=ExtResource("1_plat")]
position = Vector2(600, 1180)
platform_type = 1

[node name="ShadowPlatform2" parent="." instance=ExtResource("1_plat")]
position = Vector2(280, 1080)
platform_type = 2

[node name="DayPlatform2" parent="." instance=ExtResource("1_plat")]
position = Vector2(700, 980)
platform_type = 1

[node name="SolidPlatform1" parent="." instance=ExtResource("1_plat")]
position = Vector2(440, 880)
platform_type = 0

[node name="Checkpoint1" parent="." instance=ExtResource("3_chk")]
position = Vector2(440, 850)
saved_time = 28.0

[node name="CollisionShape2D" type="CollisionShape2D" parent="Checkpoint1"]
shape = SubResource("CS_chk")

[node name="ShadowPlatform3" parent="." instance=ExtResource("1_plat")]
position = Vector2(760, 780)
platform_type = 2

[node name="DayPlatform3" parent="." instance=ExtResource("1_plat")]
position = Vector2(280, 680)
platform_type = 1

[node name="ShadowPlatform4" parent="." instance=ExtResource("1_plat")]
position = Vector2(680, 580)
platform_type = 2

[node name="DayPlatform4" parent="." instance=ExtResource("1_plat")]
position = Vector2(200, 480)
platform_type = 1

[node name="SolidPlatform2" parent="." instance=ExtResource("1_plat")]
position = Vector2(500, 380)
platform_type = 0

[node name="DayPlatform5" parent="." instance=ExtResource("1_plat")]
position = Vector2(800, 280)
platform_type = 1

[node name="ShadowPlatform5" parent="." instance=ExtResource("1_plat")]
position = Vector2(400, 180)
platform_type = 2

[node name="ExitPortal" parent="." instance=ExtResource("2_exit")]
position = Vector2(640, 140)

[node name="CollisionShape2D" type="CollisionShape2D" parent="ExitPortal"]
shape = SubResource("CS_exit")
```

- [ ] **Step 2: Run game, reach level 4**

Expected: camera starts at bottom of level, follows player upward, stops scrolling at y=0 boundary. Level is completable from bottom to top.

- [ ] **Step 3: Commit**

```
git add scenes/levels/level_4.tscn
git commit -m "feat(level4): redesign as vertical scroll layout, 1440px tall"
```

---

### Task 5: Redesign level_5.tscn - Combined scroll (2560x1440)

**Files:**
- Modify: `scenes/levels/level_5.tscn` (full replace)

Layout: 2560x1440 world. Player travels diagonally from bottom-left to top-right. Two checkpoints. All three platform types present. Most demanding toggle puzzle of the game.

- [ ] **Step 1: Replace level_5.tscn entirely**

```
[gd_scene load_steps=6 format=3 uid="uid://solstice_lvl5"]

[ext_resource type="PackedScene" path="res://scenes/objects/platform.tscn" id="1_plat"]
[ext_resource type="PackedScene" path="res://scenes/objects/exit_portal.tscn" id="2_exit"]
[ext_resource type="PackedScene" path="res://scenes/objects/checkpoint.tscn" id="3_chk"]

[sub_resource type="RectangleShape2D" id="RS_ground"]
size = Vector2(2560, 32)

[sub_resource type="CircleShape2D" id="CS_exit"]
radius = 24.0

[sub_resource type="CircleShape2D" id="CS_chk"]
radius = 20.0

[node name="Level5" type="Node2D"]

[node name="StartPosition" type="Marker2D" parent="."]
position = Vector2(100, 1380)

[node name="Ground" type="StaticBody2D" parent="."]
position = Vector2(1280, 1440)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Ground"]
shape = SubResource("RS_ground")

[node name="ShadowPlatform1" parent="." instance=ExtResource("1_plat")]
position = Vector2(280, 1300)
platform_type = 2

[node name="DayPlatform1" parent="." instance=ExtResource("1_plat")]
position = Vector2(500, 1220)
platform_type = 1

[node name="ShadowPlatform2" parent="." instance=ExtResource("1_plat")]
position = Vector2(740, 1140)
platform_type = 2

[node name="DayPlatform2" parent="." instance=ExtResource("1_plat")]
position = Vector2(980, 1060)
platform_type = 1

[node name="SolidPlatform1" parent="." instance=ExtResource("1_plat")]
position = Vector2(1180, 980)
platform_type = 0

[node name="Checkpoint1" parent="." instance=ExtResource("3_chk")]
position = Vector2(1180, 950)
saved_time = 24.0

[node name="CollisionShape2D" type="CollisionShape2D" parent="Checkpoint1"]
shape = SubResource("CS_chk")

[node name="ShadowPlatform3" parent="." instance=ExtResource("1_plat")]
position = Vector2(1400, 880)
platform_type = 2

[node name="DayPlatform3" parent="." instance=ExtResource("1_plat")]
position = Vector2(1640, 780)
platform_type = 1

[node name="ShadowPlatform4" parent="." instance=ExtResource("1_plat")]
position = Vector2(1880, 680)
platform_type = 2

[node name="SolidPlatform2" parent="." instance=ExtResource("1_plat")]
position = Vector2(2100, 580)
platform_type = 0

[node name="Checkpoint2" parent="." instance=ExtResource("3_chk")]
position = Vector2(2100, 550)
saved_time = 17.0

[node name="CollisionShape2D" type="CollisionShape2D" parent="Checkpoint2"]
shape = SubResource("CS_chk")

[node name="DayPlatform4" parent="." instance=ExtResource("1_plat")]
position = Vector2(2260, 480)
platform_type = 1

[node name="ShadowPlatform5" parent="." instance=ExtResource("1_plat")]
position = Vector2(2380, 380)
platform_type = 2

[node name="DayPlatform5" parent="." instance=ExtResource("1_plat")]
position = Vector2(2460, 280)
platform_type = 1

[node name="ExitPortal" parent="." instance=ExtResource("2_exit")]
position = Vector2(2460, 230)

[node name="CollisionShape2D" type="CollisionShape2D" parent="ExitPortal"]
shape = SubResource("CS_exit")
```

- [ ] **Step 2: Run game, reach level 5**

Expected: camera scrolls both horizontally and vertically as player progresses diagonally. Both checkpoints reachable. Level completable.

- [ ] **Step 3: Full playthrough test**

Play through all 5 levels in sequence. Verify:
- Levels 1-2: camera does not scroll (player never leaves 1280x720 bounds)
- Level 3: camera scrolls right
- Level 4: camera scrolls up
- Level 5: camera scrolls right and up
- No visible empty space outside level bounds at any point
- Background stays fixed to viewport throughout

- [ ] **Step 4: Commit**

```
git add scenes/levels/level_5.tscn
git commit -m "feat(level5): redesign as combined scroll layout, 2560x1440"
```
