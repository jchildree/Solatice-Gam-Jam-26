# Phase 2 & 3 Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix two bugs where player state persists through respawn and day/night state persists across level loads.

**Architecture:** Add a `reset()` method to `player.gd` called by `game.gd` on respawn and level load; add `DayNightManager.reset()` called by `game.gd` on level load.

**Tech Stack:** Godot 4, GDScript

---

## File Map

- Modify: `scripts/player.gd` - add `reset()` method
- Modify: `scripts/day_night_manager.gd` - add `reset()` method
- Modify: `scripts/game.gd` - call both resets on respawn and level load

---

### Task 1: Add player reset method

**Files:**
- Modify: `scripts/player.gd`

- [ ] **Step 1: Add `reset()` to player.gd**

Append to the bottom of `scripts/player.gd`:

```gdscript
func reset() -> void:
	velocity = Vector2.ZERO
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	wall_jump_lockout = 0.0
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
```

- [ ] **Step 2: Verify in Godot editor**

Open Godot. In the script editor, confirm `reset()` appears on `player.gd` with no parse errors (no red underline in the editor, no errors in Output panel on scene load).

- [ ] **Step 3: Commit**

```bash
git add scripts/player.gd
git commit -m "feat(player): add reset() to clear movement state on respawn"
```

---

### Task 2: Add DayNightManager reset method

**Files:**
- Modify: `scripts/day_night_manager.gd`

- [ ] **Step 1: Add `reset()` to day_night_manager.gd**

Append to the bottom of `scripts/day_night_manager.gd`:

```gdscript
func reset() -> void:
	is_day = true
	cooldown_remaining = 0.0
	emit_signal("state_changed", is_day)
```

- [ ] **Step 2: Verify in Godot editor**

Open Godot. Confirm no parse errors. Open the Output panel and load the game scene -- no errors on startup.

- [ ] **Step 3: Commit**

```bash
git add scripts/day_night_manager.gd
git commit -m "feat(day-night): add reset() to restore day state on level load"
```

---

### Task 3: Wire resets into game.gd

**Files:**
- Modify: `scripts/game.gd`

- [ ] **Step 1: Call player.reset() and DayNightManager.reset() in load_level**

In `scripts/game.gd`, replace the end of `load_level()`:

```gdscript
func load_level(index: int) -> void:
	for child in level_container.get_children():
		child.queue_free()

	var scene = load(LEVELS[index])
	var level = scene.instantiate()
	level_container.add_child(level)

	for node in level.find_children("*", "Area2D", true, false):
		if node.is_in_group("checkpoint"):
			node.checkpoint_reached.connect(_on_checkpoint_reached)
		if node.is_in_group("exit"):
			node.level_complete.connect(_on_level_complete)

	var start = level.get_node_or_null("StartPosition")
	if start:
		player.global_position = start.global_position
	checkpoint_position = player.global_position
	checkpoint_saved_time = 60.0
	player.reset()
	DayNightManager.reset()
	dusk_timer.start(60.0)
```

- [ ] **Step 2: Call player.reset() in _on_dusk_reached**

Replace `_on_dusk_reached`:

```gdscript
func _on_dusk_reached() -> void:
	player.global_position = checkpoint_position
	player.reset()
	dusk_timer.reset_to_checkpoint(checkpoint_saved_time)
```

- [ ] **Step 3: Verify in Godot**

Run the game (F5). Test:
1. Press Shift to start a dash, immediately press E to toggle -- dusk fires (wait 60s) or manually trigger by editing `dusk_timer.total_time = 3.0` in the Godot inspector. Confirm player respawns cleanly, not mid-dash.
2. Complete level 1 and reach level 2 -- confirm level 2 starts in day state with full cooldown available.

- [ ] **Step 4: Commit**

```bash
git add scripts/game.gd
git commit -m "fix(game): reset player state and day-night on respawn and level load"
```
