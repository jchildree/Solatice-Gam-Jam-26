# Phase Registry

| Phase | Title | Status | Gating ADRs | Source |
|-------|-------|--------|-------------|--------|
| 01 | Tooling & Setup | COMPLETE | -- | Session 2026-06-07 |
| 02 | Core Player & Movement | COMPLETE | -- | Session 2026-06-07 |
| 03 | Day/Night System | FOCUS | ADR-001, ADR-002 | Session 2026-06-07 |
| 04 | Level Design | ACTIVE | -- | Session 2026-06-07 |
| 05 | UI & Audio | ACTIVE | ADR-002 | Session 2026-06-07 |
| 06 | Polish & Submission | DORMANT | -- | -- |

## Phase Notes

### Phase 03 - Day/Night System (FOCUS)

ADR-001 not yet implemented: toggle must deduct seconds from `DuskTimer` on each use. `DayNightManager.toggle()` currently only enforces a 1s cooldown. Level design (Phase 04) cannot be finalized until toggle cost is tuned.

ADR-002 implemented: `AudioManager` swaps BGM tracks on `state_changed`.

### Phase 04 - Level Design (ACTIVE)

5 level scenes exist. Planned revamp: levels 3-5 to introduce horizontal scrolling, vertical scrolling, and combined scrolling camera. Requires Phase 03 FOCUS exit before final tuning.

### Phase 05 - UI & Audio (ACTIVE)

`ui.gd` and `audio_manager.gd` exist. Open work: UI polish, character animations (`AnimatedSprite2D` upgrade from `Sprite2D`).
