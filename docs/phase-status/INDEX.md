# Phase Registry

| Phase | Title | Status | Gating ADRs | Source |
|-------|-------|--------|-------------|--------|
| 01 | Tooling & Setup | COMPLETE | -- | Session 2026-06-07 |
| 02 | Core Player & Movement | COMPLETE | -- | Session 2026-06-07 |
| 03 | Day/Night System | COMPLETE | ADR-001, ADR-002 | Session 2026-06-07 |
| 04 | Level Design | COMPLETE | -- | Session 2026-06-07 |
| 05 | UI & Audio | FOCUS | ADR-002 | Session 2026-06-07 |
| 06 | Polish & Submission | DORMANT | -- | -- |

## Phase Notes

### Phase 04 - Level Design (COMPLETE)

All 5 levels functional. Scrolling camera on levels 3-5 (horizontal, vertical, combined). Character displays `character.png` via AnimatedSprite2D. Platforms generate 128x16 ImageTexture at runtime - collision and visual guaranteed aligned. Per-level day/night backgrounds loaded dynamically. Tutorial background initialized. Dash mapped to Ctrl. Toggle blocked one frame on player `_ready()` to prevent tutorial E-press leaking into game.

### Phase 05 - UI & Audio (FOCUS)

`ui.gd` and `audio_manager.gd` exist. Open work: wire `AudioManager.play_sfx()` calls to actual audio files, UI polish (TimerBar, CooldownBar, StateLabel), main menu content.
