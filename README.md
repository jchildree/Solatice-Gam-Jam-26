# Solstice Game Jam '26

The sun decides where you can stand. Pick your hour - day or night - and the platforms shift beneath you. Only one path is the fastest.

Day platforms vanish at night. Night platforms hide in daylight. Master the toggle and the level becomes yours to route.

Every wasted second costs you. The fastest, cleanest runs climb the Leaderboard.

Find your line. Beat the clock. Own the board.

Built with the [Godot Engine](https://godotengine.org/) for the Solstice Game Jam 26.

## Play

Play in the browser on itch.io: https://jchildree.itch.io/solitice-game-jam-26

## How to Play

Toggle between day and night to change which platforms are solid. Day-only platforms appear in daylight; shadow-only platforms appear at night. Chain the toggle with movement to carve the shortest route to the exit, then post your time to the Leaderboard.

A dusk timer runs each level. Let it reach dusk and you respawn at the last checkpoint - plan your route before time runs out.

### Controls

| Action | Key |
|--------|-----|
| Move left | `A` / `Left` |
| Move right | `D` / `Right` |
| Jump | `Space` / `W` |
| Dash | `Ctrl` |
| Day/Night toggle | `E` |
| Pause | `Escape` |

Movement supports wall jumps and dashes - use them to reach platforms a plain jump can't.

## Project Structure

- **`scenes/`**: Godot scene files (`.tscn`) - main menu, game, levels, and object prefabs (platform, checkpoint, exit portal).
- **`scripts/`**: Core game logic in GDScript, one file per system.
- **`assets/`**: Art and audio.
- **`silent_wolf/`**: SilentWolf integration for the online Leaderboard.
- **`tools/`**: Utility scripts for development and build workflows.
- **`project.godot`**: Main Godot project configuration.

### Key systems

- **`DayNightManager`**: Autoload singleton. Owns the `is_day` state and the toggle cooldown. Platform and UI code reads from it.
- **`scripts/player.gd`**: `CharacterBody2D` - walk, jump, wall jump, dash, and day/night toggle.
- **`scripts/platform.gd`**: `platform_type` export - `0` solid, `1` day-only, `2` shadow-only.
- **`scripts/dusk_timer.gd`**: Per-level countdown. Emits `dusk_reached`; the level respawns the player at the last checkpoint.
- **`scripts/game.gd`**: Level loader. Finds checkpoints and exits by group name on load.

## Technology Stack

- **Engine:** Godot 4 (4.3+)
- **Language:** GDScript
- **Leaderboard backend:** SilentWolf
- **Tooling:** JavaScript, Python, and Shell for automation

## Getting Started

### Prerequisites

- [Godot Engine](https://godotengine.org/download/) 4.3 or newer.
- Python and Node.js if you plan to run the scripts in `tools/`.

### Run from source

1. Clone this repository:
   ```bash
   git clone https://github.com/jchildree/Solatice-Gam-Jam-26.git
   ```
2. Open Godot, click **Import**, and select the `project.godot` file in the cloned directory.
3. Click **Import & Edit**.
4. Press `F5` to run the game.

### Export to web

Export the `Web` preset (Project > Export), or run headless:

```bash
godot --headless --export-release "Web" builds/web/index.html
```

Zip the contents of `builds/web/` with `index.html` at the root, then upload to itch.io as an HTML5 game with "play in browser" enabled.

## License & Credits

- **Developer:** [GreenSide](https://github.com/jchildree)
- Created for the Solstice Game Jam 26.
- Leaderboard powered by [SilentWolf](https://silentwolf.com/).
- See `LICENSE` for license terms; asset attributions in `license.txt`.
