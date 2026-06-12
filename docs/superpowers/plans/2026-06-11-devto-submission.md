# Dev.to June Solstice Game Jam Submission Plan

> **For agentic workers:** Content task, not code. Steps use checkbox (`- [ ]`) syntax for tracking. Post draft in Task 3 is the deliverable -- publish after video embed added.

**Goal:** Publish submission post for June Solstice Game Jam on dev.to with video demo, repo embed, and Best Ode to Alan Turing prize entry.

**Architecture:** One dev.to post built from the official template. Video is the only missing asset; everything else is drafted below and ready to paste.

**Tech Stack:** dev.to editor, OBS (or any screen recorder), YouTube (video host), itch.io page already live.

---

### Task 1: Record video demo

**Files:** none (produces a video file, then a YouTube URL)

- [ ] **Step 1: Set up recording**

Record browser at https://jchildree.itch.io/solitice-game-jam-26 in fullscreen. OBS: Display Capture, 1152x648 or higher, mic enabled for voiceover. Target 60-90 seconds.

- [ ] **Step 2: Record this shot list with voiceover**

1. Title screen (5s) -- "Solatice is a solstice-themed platformer where you control time of day itself."
2. Level 2, show a DAY_ONLY platform vanish on toggle (15s) -- "Press E to flip the world between day and night. Gold platforms only exist in daylight..."
3. Level 3, SHADOW_ONLY route (15s) -- "...shadow platforms only exist at night. Every toggle costs 8 seconds of your 60-second dusk timer, so flipping the world is never free."
4. Level 4-5, hazard dodge + checkpoint respawn (15s) -- "Hazards are day- or night-bound too. Checkpoints save your position and remaining time."
5. Endless mode + SilentWolf leaderboard (15s) -- "After the 5-level campaign there's an endless mode with a global leaderboard."
6. Close on a near-miss toggle jump (10s) -- "The whole game state is a single bit -- more on that in the post."

- [x] **Step 3: Video recorded** -- `C:\Users\GreenSide\Videos\Solitice Game preview.mp4` (54MB)

### Task 2: Host video, update draft

**Files:**
- Modify: this file, Task 3 draft, `{% embed VIDEO_URL %}` line

- [ ] **Step 1: Host the video** (pick one)

1. **Dev.to cover video** -- in the dev.to post editor, upload the mp4 directly as cover video (template allows this). Then delete the `{% embed VIDEO_URL %}` line and replace the Video Demo section body with: "Video demo is the cover video above."
2. **YouTube** -- upload mp4 (unlisted or public), replace `VIDEO_URL` with the watch URL.

- [ ] **Step 2: Verify video plays in dev.to preview**

### Task 3: Publish post on dev.to

**Files:** none (dev.to editor)

- [ ] **Step 1: Create new post on dev.to, paste draft below**
- [ ] **Step 2: Add cover image** -- use itch page banner or a day/night split screenshot
- [ ] **Step 3: Verify embeds render in preview** (YouTube + GitHub)
- [ ] **Step 4: Publish, then submit post URL to jam page**

---

## Post draft

```markdown
*This is a submission for the [June Solstice Game Jam](https://dev.to/challenges/june-game-jam-2026-06-03)*

## What I Built

**Solatice** is a 2D pixel-art platformer about the solstice's central tension: day versus night. You don't wait for time to pass -- you flip it. Press E and the world toggles between Day and Night. Warm gold platforms only exist in daylight. Cold shadow platforms only exist after dark. Every jump route is a question: which world do I need to be in right now?

The catch: toggling is not free. Each level runs on a 60-second Dusk Timer, and every toggle burns 8 seconds of it. Hit zero and dusk drags you back to your last checkpoint. The solstice theme runs through the mechanics, not just the art -- the longest day of the year, and you are spending it.

Five levels teach the systems one at a time (movement, day platforms, shadow platforms, hazards, everything combined), then an endless mode with a global leaderboard takes over.

**Play it in the browser:** https://jchildree.itch.io/solitice-game-jam-26

## Video Demo

{% embed VIDEO_URL %}

## Code

{% embed https://github.com/jchildree/Solatice-Gam-Jam-26 %}

## How I Built It

Engine: **Godot 4.6**, GDScript, exported to HTML5 for itch.io.

Decisions worth sharing:

- **One bit of world state.** A `DayNightManager` autoload singleton owns a single `is_day` boolean. Platforms, hazards, music, and palette all read from it -- nothing else stores world state, so day and night can never disagree across systems.
- **Toggle as a resource.** Early playtests showed free toggling trivialized routes -- you could flip mid-air out of any mistake. Charging 8 seconds of dusk time per toggle (plus a 3s cooldown) turned it from a panic button into a budget you plan around.
- **Checkpoints save time, not just position.** A checkpoint stores your remaining Dusk Timer along with your position, so dying never refunds time you already spent. Runs stay tense without feeling unfair.
- **Palette-swap character pipeline.** The player sprite is generated through a pixelate + palette-swap pipeline, so the character recolors per world state instead of needing duplicate sprite sheets.
- **Two BGM tracks, hot-swapped on toggle.** Day and night each have their own track; the audio manager crossfades on every flip, which makes the toggle feel physical.
- **Web export with GDExtensions.** The build ships GDExtension libraries, which web exports reject by default -- fixed by enabling extensions support so Godot uses the dlink template. Uploads go through itch's butler CLI, which diff-patches builds (later uploads were ~46% smaller).
- **Global leaderboard** for endless mode via SilentWolf -- HTTPS API, works fine inside the browser sandbox.

## Prize Category

**Best Ode to Alan Turing.** Solatice's entire world is a one-bit state machine. `is_day` is the cell, the toggle key is the write head, and every platform and hazard in the level is a read head that interprets that single symbol. Playing well means doing what Turing showed machines could do: reasoning about a system's future states from its transition rules -- "if I flip the bit here, that platform exists, that hazard doesn't, and I have 8 fewer seconds of tape." The game is a love letter to how much behavior you can build on top of one binary symbol and a rule for changing it.
```

## Self-review

- Spec coverage: all five template sections filled; video section has explicit placeholder + Task 1 produces the asset. No gaps.
- Placeholders: one intentional (`VIDEO_URL`), tracked by Task 2. None hidden.
- Facts checked against CONTEXT.md and git history: toggle cost 8s, timer 60s, cooldown 3s, 5 levels, SilentWolf, palette-swap pipeline, dlink fix -- all match.
