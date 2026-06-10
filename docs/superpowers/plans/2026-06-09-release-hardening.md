# Plan: Release Hardening

Date: 2026-06-09
Status: approved (architecture review candidates 1-5, all accepted)

## Goal

Fix all defects and deepening opportunities from the pre-release architecture review.
Three parallel agents grouped by file ownership (zero shared files), plus inline
cleanup of stray files.

## File ownership

- Agent G (game flow): game.gd, tutorial.gd, dusk_timer.gd, game_session.gd
- Agent E (endless + platform + ui): endless.gd, endless_chunk.gd, platform.gd, ui.gd, endless.tscn
- Agent L (leaderboard): leaderboard.gd, win.gd, main_menu.gd
- Inline (main thread): delete test_scene.tscn, control.tscn, demo/

## Pinned API contracts (cross-agent, must match exactly)

1. GameSession.respawn_player(player: Node, position: Vector2) -> void
   Sets player.global_position, calls player.reset(), calls DayNightManager.reset().
   DuskTimer handling stays caller-side (game.gd only).
2. GameSession.day_sky_textures() -> Array and night_sky_textures() -> Array
   Load (and cache) textures from DAY_SKY_LAYERS / NIGHT_SKY_LAYERS paths.
3. Leaderboard.fetch_top_text(board: String, count: int, callback: Callable) -> void
   Fetches entries, formats per board ("time" -> GameSession.format_ms, "distance" ->
   "%dm"), invokes callback with one formatted String ready for a Label.

Agent G implements 1-2; Agent L implements 3; Agent E consumes 2-3.

## Work items

### Agent G

- Respawn module: replace duplicated respawn sequences in game.gd (fall, dusk expiry)
  with GameSession.respawn_player + caller-side dusk_timer.reset_to_checkpoint.
- Fix tutorial.gd respawn drift bug: missing DayNightManager.reset() (dying at Night
  respawns still at Night).
- Sky texture API in game_session.gd; convert game.gd and tutorial.gd call sites.

### Agent E

- ui.gd: null-safe DuskTimer lookup; hide timer bar when group absent (endless mode).
- platform.gd: texture cache key must include platform_type (same-size platforms of
  different types currently share first type's texture).
- endless.gd / endless_chunk.gd: reference platform.gd PlatformType enum instead of
  raw ints; single owner for CHUNK_WIDTH const.
- endless.gd: convert sky-layer loading to GameSession.day_sky_textures()/night_...;
  convert leaderboard block to Leaderboard.fetch_top_text("distance", ...).

### Agent L

- leaderboard.gd: fetch_top_text API (contract 3); HTTPRequest lifecycle -- guard
  callbacks with is_instance_valid, free request nodes on completion, prevent
  overlapping-request node leak.
- win.gd, main_menu.gd: replace duplicated format loops with fetch_top_text.

### Inline

- Delete test_scene.tscn, control.tscn, demo/ (all untracked, unreferenced).

## Verification

- Main thread reviews every diff after agents return.
- grep for stale references (fetch(), DAY_SKY_LAYERS.map, raw platform_type ints).
- No Godot CLI on machine: user F5 pass for main levels, tutorial death at Night,
  endless mode UI, win screen + menu leaderboards.

## Out of scope (follow-ups)

- addons/ holds 6 unused libraries (foley_ai, godot-rapier2d, limboai,
  quaternius_ik_rigged, rhythm_notifier, vaporwavesky) -- export size concern,
  separate decision.
- Hidden Sprite2D nodes in 4 scenes (harmless, .tscn edits not worth risk now).
