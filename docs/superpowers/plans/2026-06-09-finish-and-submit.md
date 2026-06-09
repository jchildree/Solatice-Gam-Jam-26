# Finish and Submit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete Phase 05 and Phase 06 -- win screen, UI polish, tutorial kill zone, and web export -- to bring the game to a submittable state.

**Architecture:** All changes are additive. New `win.tscn` + `scripts/win.gd` handle the victory flow. UI polish is pure scene/theme edits. Kill zone is a single Area2D in `tutorial.tscn`. Export is a Godot project setting operation.

**Tech Stack:** Godot 4.3+, GDScript, HTML5 export template

---

## Current State

- Phase 01-04: COMPLETE.
- Phase 05 (UI & Audio): FOCUS. Music done. SFX procedural fallback active (no WAV files). UI wired but visually plain. No win screen.
- Phase 06 (Polish & Submission): DORMANT.
- Completing all 5 levels returns player to main menu silently -- no victory feedback.
- Tutorial has no kill zone -- falling off bottom loops forever.

---

## File Map

| File | Action | Purpose |
|------|--------|---------|
| `scenes/win.tscn` | Create | Victory screen shown after level 5 |
| `scripts/win.gd` | Create | Auto-return to menu after delay |
| `scenes/game.tscn` | No change | `game.gd` already calls `change_scene_to_file` at end |
| `scripts/game.gd` | Modify | Point final scene change to `win.tscn` instead of `main_menu.tscn` |
| `scenes/tutorial.tscn` | Modify | Add kill zone Area2D at bottom |
| `scripts/tutorial.gd` | Modify | Connect kill zone body_entered to restart tutorial |
| `scripts/ui.gd` | Modify | Add color feedback to TimerBar (green/yellow/red) |

---

### Task 1: Win Screen

**Files:**
- Create: `scenes/win.tscn`
- Create: `scripts/win.gd`
- Modify: `scripts/game.gd:96-101`

The game currently calls `get_tree().change_scene_to_file("res://scenes/main_menu.tscn")` after level 5. Redirect this to a new win scene.

- [ ] **Step 1: Create `scripts/win.gd`**

  ```gdscript
  extends Control

  const RETURN_DELAY := 6.0

  var _timer: float = 0.0

  func _process(delta: float) -> void:
  	_timer += delta
  	if _timer >= RETURN_DELAY or Input.is_action_just_pressed("jump"):
  		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
  ```

- [ ] **Step 2: Create `scenes/win.tscn` in Godot editor**

  In the Godot editor:
  1. Scene > New Scene
  2. Root node: `Control` -- rename to `Win`
  3. Attach script: `res://scripts/win.gd`
  4. Set anchors to full-rect (Anchor Preset 15)
  5. Add child `ColorRect` -- fill screen, color `Color(0.05, 0.02, 0.15, 1)`
  6. Add child `VBoxContainer` -- center it (anchor 0.5/0.5, offset -150/-60 to 150/60)
  7. Add `Label` child named `Title` -- text `"YOU REACHED THE SHRINE"`, `horizontal_alignment = CENTER`, font size 32
  8. Add `Label` child named `Subtitle` -- text `"The solstice is saved."`, `horizontal_alignment = CENTER`, font size 18
  9. Add `Label` child named `Hint` -- text `"Press Space to return"`, `horizontal_alignment = CENTER`, font size 14
  10. Save as `res://scenes/win.tscn`

- [ ] **Step 3: Update `scripts/game.gd` to point to win scene**

  Change line 99 in `scripts/game.gd`:

  ```gdscript
  func _on_level_complete() -> void:
  	current_level_index += 1
  	if current_level_index >= LEVELS.size():
  		get_tree().change_scene_to_file("res://scenes/win.tscn")
  	else:
  		load_level(current_level_index)
  ```

- [ ] **Step 4: Verify manually**

  Run the game. Use Godot debugger console to skip to level 5 or walk through the exit portal. Expected: win screen appears with title text. After 6 seconds OR pressing Space, returns to main menu.

- [ ] **Step 5: Commit**

  ```bash
  git add scenes/win.tscn scripts/win.gd scripts/game.gd
  git commit -m "feat(ui): add win screen after level 5 complete"
  ```

---

### Task 2: Tutorial Kill Zone

**Files:**
- Modify: `scenes/tutorial.tscn`
- Modify: `scripts/tutorial.gd`

Tutorial has no ground kill zone. Player falls off bottom and falls forever with no reset.

- [ ] **Step 1: Add kill zone to `scenes/tutorial.tscn` in Godot editor**

  Open `tutorial.tscn`. Under root node `Tutorial`:
  1. Add `Area2D` node, name it `KillZone`, add to group `kill_zone`
  2. Add `CollisionShape2D` child -- shape `RectangleShape2D`, size `Vector2(1280, 32)`
  3. Set `KillZone` position to `Vector2(640, 500)` (below the floor at y=400)
  4. Save scene

  The resulting node lines in the `.tscn` file will look like:
  ```
  [node name="KillZone" type="Area2D" parent="."]
  position = Vector2(640, 500)
  ```

- [ ] **Step 2: Update `scripts/tutorial.gd` to reset on kill**

  ```gdscript
  extends Node2D

  const STEPS = [
  	{ "actions": ["move_left", "move_right"], "prompt": "Press A or D to move" },
  	{ "actions": ["jump"], "prompt": "Press Space to jump" },
  	{ "actions": ["dash"], "prompt": "Press Ctrl to dash" },
  	{ "actions": ["toggle"], "prompt": "Press E to toggle day and night" },
  ]

  var current_step: int = 0

  @onready var prompt_label: Label = $UI/PromptLabel
  @onready var player: CharacterBody2D = get_tree().get_first_node_in_group("player")

  func _ready() -> void:
  	$Background.set_level_textures(
  		load("res://assets/sprites/backgrounds/bg_l1_day.png"),
  		load("res://assets/sprites/backgrounds/bg_l1_night.png")
  	)
  	_show_step(0)
  	AudioManager.play_music("day")
  	$KillZone.body_entered.connect(_on_kill_zone_entered)

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

  func _on_kill_zone_entered(body: Node) -> void:
  	if body.is_in_group("player"):
  		body.global_position = Vector2(200, 340)
  		body.reset()
  ```

- [ ] **Step 3: Verify manually**

  Run tutorial. Walk off the edge. Expected: player teleports back to start position `Vector2(200, 340)` instead of falling forever.

- [ ] **Step 4: Commit**

  ```bash
  git add scenes/tutorial.tscn scripts/tutorial.gd
  git commit -m "fix(tutorial): add kill zone to reset player on fall"
  ```

---

### Task 3: TimerBar Color Feedback

**Files:**
- Modify: `scripts/ui.gd`

TimerBar is a flat ProgressBar. Add color feedback: green when time is healthy, yellow when low, red when critical.

- [ ] **Step 1: Update `scripts/ui.gd`**

  ```gdscript
  extends CanvasLayer

  @onready var timer_bar: ProgressBar = $TimerBar
  @onready var cooldown_bar: ProgressBar = $CooldownBar
  @onready var state_label: Label = $StateLabel

  func _ready() -> void:
  	DayNightManager.state_changed.connect(_on_state_changed)
  	var dusk_timer = get_tree().get_first_node_in_group("dusk_timer")
  	if dusk_timer:
  		dusk_timer.time_updated.connect(_on_time_updated)
  	_on_state_changed(DayNightManager.is_day)

  func _process(_delta: float) -> void:
  	cooldown_bar.value = 1.0 - DayNightManager.get_cooldown_percent()

  func _on_time_updated(remaining: float, total: float) -> void:
  	var ratio := remaining / total
  	timer_bar.value = ratio
  	var color: Color
  	if ratio > 0.5:
  		color = Color(0.2, 0.8, 0.3)
  	elif ratio > 0.25:
  		color = Color(0.9, 0.7, 0.1)
  	else:
  		color = Color(0.9, 0.2, 0.1)
  	timer_bar.add_theme_color_override("fill_color", color)

  func _on_state_changed(is_day: bool) -> void:
  	state_label.text = "DAY" if is_day else "NIGHT"
  ```

- [ ] **Step 2: Verify manually**

  Run a level. Watch TimerBar as time decreases. Expected: green at start, shifts to yellow at 50%, red at 25%.

- [ ] **Step 3: Commit**

  ```bash
  git add scripts/ui.gd
  git commit -m "feat(ui): timer bar color feedback green/yellow/red"
  ```

---

### Task 4: Web Export Setup

**Files:**
- No code files -- Godot project settings only

Game jam submissions typically require a web (HTML5) build.

- [ ] **Step 1: Install HTML5 export template**

  In Godot editor: Editor > Manage Export Templates > Download and Install (for your Godot version, e.g. 4.3).

- [ ] **Step 2: Add HTML5 export preset**

  Project > Export > Add > Web.

  Required settings:
  - Export Path: `export/web/index.html`
  - Runnable: checked
  - VRAM Texture Compression > For Desktop: checked

- [ ] **Step 3: Create export directory**

  ```bash
  mkdir -p export/web
  ```

  Add to `.gitignore`:
  ```
  export/
  ```

- [ ] **Step 4: Export and test locally**

  In Godot: Project > Export > Export All (or Export Project with the Web preset selected).

  Serve locally to test (browser blocks file:// for web exports):
  ```bash
  cd export/web && python -m http.server 8080
  ```

  Open `http://localhost:8080` in browser. Expected: game loads, plays, music works, levels complete.

- [ ] **Step 5: Commit .gitignore update**

  ```bash
  git add .gitignore
  git commit -m "chore: ignore export/ build output"
  ```

---

### Task 5: Phase Status Update

**Files:**
- Modify: `docs/phase-status/INDEX.md`

- [ ] **Step 1: Update phase registry**

  ```markdown
  # Phase Registry

  | Phase | Title | Status | Gating ADRs | Source |
  |-------|-------|--------|-------------|--------|
  | 01 | Tooling & Setup | COMPLETE | -- | Session 2026-06-07 |
  | 02 | Core Player & Movement | COMPLETE | -- | Session 2026-06-07 |
  | 03 | Day/Night System | COMPLETE | ADR-001, ADR-002 | Session 2026-06-07 |
  | 04 | Level Design | COMPLETE | -- | Session 2026-06-07 |
  | 05 | UI & Audio | COMPLETE | ADR-002 | Session 2026-06-09 |
  | 06 | Polish & Submission | COMPLETE | -- | Session 2026-06-09 |

  ## Phase Notes

  ### Phase 05 - UI & Audio (COMPLETE)

  Lofi MP3 music tracks added. OGG loop bug fixed. TimerBar color feedback (green/yellow/red). SFX procedural fallback active -- no WAV files sourced (acceptable for jam).

  ### Phase 06 - Polish & Submission (COMPLETE)

  Win screen added (auto-returns to menu after 6s or Space). Tutorial kill zone prevents infinite fall. Web export preset configured. Build exported to `export/web/`.
  ```

- [ ] **Step 2: Commit**

  ```bash
  git add docs/phase-status/INDEX.md
  git commit -m "docs: mark phase 05 and 06 complete"
  ```

---

## Notes

- SFX WAV files are optional -- procedural fallback (beeps) is good enough for a jam submission. Source them post-jam if desired.
- The `export/` directory should NOT be committed -- it can be 50MB+.
- Itch.io web upload: zip the contents of `export/web/` and upload as HTML game. Set viewport to 1280x720.
- If the Godot HTML5 export shows a black screen locally, serve it via `python -m http.server` -- browsers block SharedArrayBuffer on `file://`.
