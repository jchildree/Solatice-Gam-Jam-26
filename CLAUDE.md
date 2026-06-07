# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Status

This is a game jam project for the Solatice Game Jam 2026. The game code has not been written yet - only the Claude Code tooling configuration exists.

## Tooling

Hooks in `.claude/settings.json` fire on session start and file writes:
- `caveman-activate.js` - loads caveman communication mode
- `skill-metadata-loader.js` - loads skill metadata into context
- `wiki-memory-inject.js` - injects wiki memory into context
- `caveman-mode-tracker.js` - tracks caveman mode on prompt submit
- `check-encoding.js` - validates file encoding after Write/Edit tool calls (enforces no BOM, no non-ASCII punctuation)

## Architecture Notes

Engine: Godot 4 (GDScript). Open `project.godot` in Godot 4.3+.

Run: press F5 in Godot editor, or export to Windows/web via Project > Export.

### Key systems

- `DayNightManager` - autoload singleton. Owns `is_day` state and toggle cooldown. All platform and UI code reads from this.
- `scripts/player.gd` - `CharacterBody2D`. Walk, jump, wall jump, dash, toggle (E key).
- `scripts/platform.gd` - export `platform_type`: 0=SOLID, 1=DAY_ONLY, 2=SHADOW_ONLY.
- `scripts/dusk_timer.gd` - countdown node. Emits `dusk_reached`; `game.gd` respawns player at checkpoint.
- `scripts/game.gd` - level loader. Finds checkpoints/exits by group name on level load.

### Input map

| Action | Key |
|--------|-----|
| move_left | A / Left |
| move_right | D / Right |
| jump | Space / W |
| dash | Ctrl |
| toggle | E |

### Project structure

```
scenes/
  main_menu.tscn
  game.tscn
  objects/   -- platform, checkpoint, exit_portal
  levels/    -- level_1 through level_5
scripts/     -- one .gd per system
assets/
  audio/
  sprites/
```

## Agent skills

### Issue tracker

Issues live as markdown files under `.scratch/<feature>/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Default label vocabulary (needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout -- one `CONTEXT.md` and `docs/adr/` at repo root. See `docs/agents/domain.md`.
