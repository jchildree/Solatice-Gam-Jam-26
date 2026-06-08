# Phase Registry

| Phase | Title | Status | Gating ADRs | Source |
|-------|-------|--------|-------------|--------|
| 01 | Tooling & Setup | COMPLETE | -- | Session 2026-06-07 |
| 02 | Core Player & Movement | COMPLETE | -- | Session 2026-06-07 |
| 03 | Day/Night System | COMPLETE | ADR-001, ADR-002 | Session 2026-06-07 |
| 04 | Level Design | FOCUS | -- | Session 2026-06-07 |
| 05 | UI & Audio | ACTIVE | ADR-002 | Session 2026-06-07 |
| 06 | Polish & Submission | DORMANT | -- | -- |

## Phase Notes

### Phase 04 - Level Design (FOCUS)

5 level scenes exist. Open work: levels 3-5 revamp to introduce scrolling camera (horizontal, vertical, combined). Platform visual/physics alignment fixed. All platforms use base 128x16 collision from platform.tscn; sprite scales to match at runtime.

### Phase 05 - UI & Audio (ACTIVE)

`ui.gd` and `audio_manager.gd` exist. Open work: UI polish, character animations (`AnimatedSprite2D` upgrade from `Sprite2D`).
