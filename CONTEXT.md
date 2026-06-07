# CONTEXT.md

Game jam project for Solatice Game Jam 2026. Solstice-themed 2D platformer.

## Domain language

- **Toggle** -- player action (E key) that switches world state between Day and Night. 3s cooldown. Costs 8 seconds from DuskTimer.
- **Day** -- world state where DAY_ONLY platforms are solid/visible, SHADOW_ONLY platforms vanish.
- **Night** -- world state where SHADOW_ONLY platforms are solid/visible, DAY_ONLY platforms vanish.
- **DuskTimer** -- 60-second countdown per level. Expiry respawns player at last Checkpoint. Resets on checkpoint save.
- **Checkpoint** -- saves player position and current DuskTimer value. Player respawns here on dusk.
- **Platform** -- static body with one of three types: SOLID (always present), DAY_ONLY, SHADOW_ONLY.
- **Hazard** -- environmental obstacle (spike, crusher, moving platform). No AI. Can be day-only or night-only like platforms. Kills player on contact, respawns at last Checkpoint.
- **Level** -- one of 5 scenes (level_1 through level_5). Beaten by reaching Exit Portal. Progression: L1=controls only, L2=DAY_ONLY platforms, L3=SHADOW_ONLY platforms, L4=hazards introduced, L5=all systems combined.
- **Win Screen** -- dedicated scene shown after level 5. Shows completion message, total time score across all levels, and play-again button. Not main menu.
- **Time Score** -- sum of elapsed seconds across all 5 levels. Lower = better. Displayed on Win Screen.

## Bounded contexts

Single context -- all systems in one Godot scene tree.

## Audio

- **BGM** -- background music. Two tracks: one for Day, one for Night. AudioManager swaps on Toggle. SFX: jump, land, dash.

## Visual style

Pixel art. Day palette: warm oranges/yellows. Night palette: deep blues/purples. High contrast between states for gameplay readability.

## Constraints

- Game jam scope: small, shippable game
- Engine: Godot 4 (GDScript)
- 5 levels total
- Export target: Web (HTML5) for itch.io. Audio needs user interaction before first play -- title screen click satisfies this.
