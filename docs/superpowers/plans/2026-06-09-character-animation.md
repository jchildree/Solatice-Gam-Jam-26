# Plan: Animated Pixel-Kid Character

Date: 2026-06-09
Status: approved (grill-me interview complete)

## Goal

Replace the static `character.png` sprite with a fully animated pixel-art character that
keeps the pixel kid's identity (exact palette) while reusing the six existing animation
sheets in `assets/sprites/animations/` as pose source material.

## Decisions (from interview)

1. **Art direction**: new character matching pixel kid, driven by existing animation sheets.
2. **Production**: script-based pipeline -- pixelate + palette-swap the silhouette sheets.
   No hand-drawn frames, no external AI tools, no asset packs.
3. **State mapping**:
   - Idle = static first Walking frame + existing procedural sine bob.
   - Dash = Roll animation.
   - Ground movement = Running only (Walking sheet unused; no walk/run speed gradation).
   - Rising = Jumping, descending = Falling, touchdown = Landing.
4. **Resolution**: 48x48 frames (fallback to 32x32 if too clean-looking).
5. **Procedural juice**: keep landing/jump squash-stretch layered on the animated sprite;
   drop run-bob-while-moving and dash tilt (Running/Roll animations replace them).
   Idle bob stays.
6. **Palette**: exact current kid palette -- green cap, light skin, dark-red shirt,
   blue jeans, black shoes. Sampled from `assets/sprites/character.png`.
7. **Segmentation (hybrid)**:
   - Upright sheets (Walking, Running, Jumping, Falling, Landing): vertical region bands
     within per-frame body bounding box -- top ~20% cap/skin, middle shirt, lower jeans,
     bottom ~10% shoes. Source tone preserved as shading within each band.
   - Roll: two-tone tint only (light tones -> shirt red, dark tones -> jeans blue) to
     avoid band smearing on rotated body.
8. **Integration**: code-built in `player.gd _ready()` -- construct `SpriteFrames` from
   processed sheets, spawn `AnimatedSprite2D`, hide/repurpose old `Sprite2D`.
   Zero .tscn edits; all 4 scenes containing an inline Player node (game, endless,
   tutorial, main_menu) pick it up automatically.
9. **Day/night**: subtle night modulate (blue-dim tint) on the character, lerped from
   `DayNightManager.is_day`.
10. **Collision**: capsule (r=16, h=64) untouched. Sprite scaled so feet align with
    capsule bottom.

## Source material facts

- Sheets: 128x128 per frame, horizontal strips.
- Frame counts: Walking 12, Running 12, Falling 11, Jumping 10, Roll 9, Landing 6 (60 total).
- Style: smooth blue humanoid silhouette (light blue = near limb, dark navy = far limb) --
  tones do NOT map to body parts, hence region-band segmentation.

## Steps

### Step 1: Asset pipeline script

`tools/build_character_frames.py` (Python + Pillow):

1. Sample palette colors from `assets/sprites/character.png` (cap green, skin, shirt
   dark red, jeans blue, shoe black).
2. For each sheet: split into 128x128 frames, compute per-frame body bounding box
   (non-transparent pixels).
3. Upright sheets: apply vertical band mapping (cap/skin / shirt / jeans / shoes) with
   tone-preserving shading. Roll: two-tone tint.
4. Downscale each frame to 48x48 nearest-neighbor.
5. Reassemble horizontal strips, write to `assets/sprites/animations/processed/<name>.png`
   as PNG (UTF-8 paths, no metadata weirdness).
6. Idle: extract first Walking frame as `processed/Idle.png` (single frame).

Verification: open output PNGs, eyeball band placement on a walk frame, a jump frame,
and a roll frame. Iterate band percentages if cap bleeds into shirt etc.

### Step 2: player.gd animation integration

1. `_ready()`: build `SpriteFrames` resource in code -- one animation per processed
   sheet (idle, run, jump, fall, land, roll) with frame counts above; FPS roughly:
   run 14, jump 12, fall 12, land 18 (one-shot), roll ~60/9 to fit 0.15s dash window
   (or play at fixed 20 FPS and let it truncate -- tune in test).
2. Spawn `AnimatedSprite2D` child, hide old `Sprite2D` (keep node so .tscn untouched).
3. State machine in `_update_sprite()` (rename/refactor):
   - dashing -> roll
   - airborne & velocity.y < 0 -> jump
   - airborne & velocity.y >= 0 -> fall
   - just landed -> land (one-shot, then fall through to idle/run)
   - |velocity.x| > 10 on floor -> run
   - else -> idle (static frame + sine bob on sprite position.y)
4. Keep squash-stretch: apply scale lerp to the AnimatedSprite2D (jump launch squash,
   landing squash). Remove run-bob-during-move and dash tilt.
5. `flip_h` from move direction (existing logic).
6. Night tint: modulate lerp toward dim blue when `not DayNightManager.is_day`.
7. Scale sprite so 48px frame's feet sit at capsule bottom (capsule is 64 tall +
   16 radius caps; tune constant visually).
8. Update `reset()` for new node (scale/rotation/position + animation back to idle).

### Step 3: Verify in-game

1. Run game (F5 / godot --path). Check tutorial, level 1, endless.
2. Confirm: run cycle plays, jump/fall transition mid-arc, landing one-shot fires with
   squash, dash shows roll, idle bobs, flip works both directions, night toggle tints.
3. Confirm no errors from main_menu scene (its inline Player also runs player.gd).
4. Drop to 32x32 only if 48 reads as "shrunken render" instead of pixel art.

## Risks

- Band segmentation artifacts on extreme poses (deep landing crouch puts head in shirt
  band). Mitigation: bands computed from per-frame bounding box, not frame rect; iterate
  percentages per-sheet if needed.
- Roll two-tone may look disconnected from banded frames. Acceptable: visible 0.15s.
- Landing one-shot racing state machine (re-enter run/idle before finish). Mitigation:
  small lock timer or `animation_finished` signal gate.

## Out of scope

- Walking sheet (unused), checkpoint/portal animation, new player abilities,
  .tscn restructuring into shared player scene.
