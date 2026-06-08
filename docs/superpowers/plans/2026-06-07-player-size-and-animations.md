# Player Size and Tween Animations Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scale the player up 1.5x and add tween-based running bob, jump squash, and land squash animations to the stick figure sprite.

**Architecture:** Size increase is a scene-file change (collision shape + sprite scale). Animations live entirely in `player.gd` using Godot 4 `Tween` objects -- no new files or AnimatedSprite2D needed. A `BASE_SCALE` constant keeps squash/stretch relative to the new size so animations remain correct if size changes again.

**Tech Stack:** Godot 4, GDScript, Godot Tween API

---

## File Map

- Modify: `scenes/game.tscn` -- collision shape radius/height + Sprite2D scale
- Modify: `scenes/tutorial.tscn` -- same
- Modify: `scripts/player.gd` -- BASE_SCALE, tween vars, animation helpers, hook into jump/land/run

---

### Task 1: Increase player size in scene files

**Files:**
- Modify: `scenes/game.tscn`
- Modify: `scenes/tutorial.tscn`

- [ ] **Step 1: Update collision shape in game.tscn**

Find the sub_resource block (around line 10-12):

```
[sub_resource type="CapsuleShape2D" id="CS_player"]
radius = 10.0
height = 48.0
```

Replace with:

```
[sub_resource type="CapsuleShape2D" id="CS_player"]
radius = 16.0
height = 64.0
```

- [ ] **Step 2: Update Sprite2D scale in game.tscn**

Find the Sprite2D node block (around line 31-32):

```
[node name="Sprite2D" type="Sprite2D" parent="Player"]
texture = ExtResource("5_spr01")
```

Replace with:

```
[node name="Sprite2D" type="Sprite2D" parent="Player"]
scale = Vector2(1.5, 1.5)
texture = ExtResource("5_spr01")
```

- [ ] **Step 3: Update collision shape in tutorial.tscn**

Find the sub_resource block:

```
[sub_resource type="CapsuleShape2D" id="CS_player"]
radius = 10.0
height = 48.0
```

Replace with:

```
[sub_resource type="CapsuleShape2D" id="CS_player"]
radius = 16.0
height = 64.0
```

- [ ] **Step 4: Update Sprite2D scale in tutorial.tscn**

Find:

```
[node name="Sprite2D" type="Sprite2D" parent="Player"]
texture = ExtResource("5_spr")
```

Replace with:

```
[node name="Sprite2D" type="Sprite2D" parent="Player"]
scale = Vector2(1.5, 1.5)
texture = ExtResource("5_spr")
```

- [ ] **Step 5: Verify in Godot editor**

Open Godot. Open `scenes/game.tscn`. Click the Player node, then Sprite2D -- confirm Scale shows (1.5, 1.5) in the Inspector. Click CollisionShape2D -- confirm Radius=16, Height=64. Run the scene (F5) and confirm the player is visibly larger. No errors in Output.

- [ ] **Step 6: Commit**

```bash
git add scenes/game.tscn scenes/tutorial.tscn
git commit -m "feat(player): increase player size 1.5x (collision radius 10->16, height 48->64)"
```

---

### Task 2: Add tween animations to player.gd

**Files:**
- Modify: `scripts/player.gd`

Animations:
- **Running bob:** Sprite2D.position.y oscillates +-4px while moving on floor
- **Jump squash:** horizontal squeeze + vertical stretch on jump, then recover
- **Land squash:** horizontal stretch + vertical squeeze on land, then recover

- [ ] **Step 1: Add BASE_SCALE constant and tween variables**

After the existing constants block (after `APEX_THRESHOLD`), add:

```gdscript
const BASE_SCALE = Vector2(1.5, 1.5)

var _run_tween: Tween
var _running: bool = false
```

- [ ] **Step 2: Add animation helper methods**

Append these methods after `reset()` and before `_handle_dash()`:

```gdscript
func _start_run_tween() -> void:
	if _running:
		return
	_running = true
	if _run_tween:
		_run_tween.kill()
	_run_tween = create_tween().set_loops()
	_run_tween.tween_property($Sprite2D, "position:y", -4.0, 0.1)
	_run_tween.tween_property($Sprite2D, "position:y", 4.0, 0.1)

func _stop_run_tween() -> void:
	if not _running:
		return
	_running = false
	if _run_tween:
		_run_tween.kill()
		_run_tween = null
	create_tween().tween_property($Sprite2D, "position:y", 0.0, 0.08)

func _on_jump() -> void:
	_stop_run_tween()
	$Sprite2D.position.y = 0.0
	var t = create_tween()
	t.tween_property($Sprite2D, "scale", BASE_SCALE * Vector2(0.75, 1.3), 0.07)
	t.tween_property($Sprite2D, "scale", BASE_SCALE, 0.1)

func _on_land() -> void:
	_stop_run_tween()
	$Sprite2D.position.y = 0.0
	var t = create_tween()
	t.tween_property($Sprite2D, "scale", BASE_SCALE * Vector2(1.3, 0.75), 0.06)
	t.tween_property($Sprite2D, "scale", BASE_SCALE, 0.1)
```

- [ ] **Step 3: Add run animation update to _physics_process**

After `move_and_slide()` and before the `_was_on_floor` check, add:

```gdscript
	var moving_on_floor = is_on_floor() and abs(velocity.x) > 10.0
	if moving_on_floor:
		_start_run_tween()
	else:
		_stop_run_tween()
```

- [ ] **Step 4: Call _on_jump() at both jump sites**

In the floor jump block, add `_on_jump()` after `velocity.y = JUMP_VELOCITY`:

```gdscript
			if coyote_timer > 0:
				velocity.y = JUMP_VELOCITY
				_on_jump()
				coyote_timer = 0.0
				jump_buffer_timer = 0.0
				AudioManager.play_sfx("jump")
```

In the wall jump block, add `_on_jump()` after the velocity assignment:

```gdscript
			elif is_on_wall():
				var normal = get_wall_normal()
				velocity = Vector2(normal.x * WALL_JUMP_H, WALL_JUMP_V)
				_on_jump()
				jump_buffer_timer = 0.0
				wall_jump_lockout = WALL_JUMP_LOCKOUT_TIME
				AudioManager.play_sfx("jump")
```

- [ ] **Step 5: Call _on_land() at the landing detection site**

Replace the landing block:

```gdscript
	if not _was_on_floor and is_on_floor():
		AudioManager.play_sfx("land")
		_on_land()
	_was_on_floor = is_on_floor()
```

- [ ] **Step 6: Reset sprite state in reset()**

Add sprite cleanup to the existing `reset()` method:

```gdscript
func reset() -> void:
	velocity = Vector2.ZERO
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	wall_jump_lockout = 0.0
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	_was_on_floor = true
	if _run_tween:
		_run_tween.kill()
		_run_tween = null
	_running = false
	$Sprite2D.scale = BASE_SCALE
	$Sprite2D.position.y = 0.0
```

- [ ] **Step 7: Verify in Godot editor**

Run the game (F5). Walk right -- sprite bobs up and down. Stop -- bob stops and sprite settles. Jump -- sprite squashes thin/tall briefly. Land -- sprite squashes wide/short briefly then recovers. No errors in Output.

- [ ] **Step 8: Commit**

```bash
git add scripts/player.gd
git commit -m "feat(player): add tween running bob, jump squash, and land squash animations"
```
