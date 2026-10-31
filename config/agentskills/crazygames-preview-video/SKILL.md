---
name: crazygames-preview-video
description: Create, convert and validate the hover preview videos required when submitting a game to CrazyGames (15-20s, no sound, landscape 1920x1080 + portrait 2:3, under 50MB, cover as first frame). Use this skill whenever the user mentions CrazyGames preview video, hover video, game thumbnail video, trailer or gameplay clip for CrazyGames, or has raw gameplay footage / a game they want turned into a submission-ready video, even if they never say "preview". Also use it to check why a CrazyGames video was rejected or to re-export an existing clip.
compatibility: Requires ffmpeg and ffprobe on PATH, and Python 3.
---

# CrazyGames preview video

CrazyGames plays a short muted video when a player hovers over a game's cover. The submission form asks for two versions (landscape and portrait). Videos that break the rules get bounced in review, and a weak preview costs clicks, so the goal is a clean, exciting clip that passes on the first try.

Source of truth: https://docs.crazygames.com/requirements/game-covers/#preview-video. The rules can change, so if the user reports a different requirement, trust them and re-check that page.

## Requirements (as of the docs)

| Item | Rule |
|---|---|
| Length | 15-20 s. Anything longer is cut to 20 s |
| Size | 50 MB max per file |
| Landscape | 1920x1080 (16:9), mandatory |
| Portrait | 1080x1620 (2:3), mandatory |
| Audio | None. Strip the audio track |
| First frame | The static cover image, so the thumbnail flows into the video |
| Speed | No fast-forwarding; CrazyGames already speeds the video up slightly |
| Avoid | Black bars, black screen or logo transitions, the default mouse cursor, "Play Now" or promo text, app/social icons |
| Content | May be animated, but must represent the real gameplay and not mislead |

Portrait is read here as 1080 wide x 1620 tall (1080p width at 2:3). If the submission form shows a different expected size, pass `--portrait-size WxH` to the script.

## Workflow

1. **Gather inputs.** Needed: raw gameplay footage (or the game itself to record), the landscape cover (1920x1080) and the portrait cover (800x1200). Covers matter because the video must open on them. If a cover is missing, ask the user for it rather than inventing one. Covers must also follow CrazyGames' rules (3 sizes, game title only, no borders or store icons), but producing covers is out of scope here.

2. **Plan the clip.** Pick the 15-20 s that sell the game fastest: best moment first, then variety. Genre hints from the docs:
   - Driving: fast or expensive cars, different maps and weather, a dashboard camera angle.
   - Multiplayer: a full lobby, several maps, the biggest celebration or prize.
   - Action: intense fights, several modes and weapons, impressive builds.
   - Progression: character evolution and customization across modes.
   - Idle/clicker/puzzle: show the loop paying off (numbers climbing, a satisfying combo or solve), because the hook is the reward, not the controls.
   Use end-game saves or debug unlocks to show the best content; that is explicitly encouraged.

3. **Record clean footage.** Hide the OS cursor (or use the game's own in-game cursor), record at 1080p or higher with no browser chrome, and keep audio off. A portrait video looks much better recorded in a portrait viewport (e.g. 540x810 or 1080x1620) than cropped from landscape footage, so if the game supports resizing, record twice. Useful capture options:
   - Godot 4: `godot --path <project> --write-movie out.avi --fixed-fps 60` (Movie Maker mode, frame-perfect, no dropped frames).
   - HTML5 games: Playwright with `recordVideo`, or OBS / the OS screen recorder on a fixed-size window.

4. **Build both videos** with the bundled script. It trims, scales to fill (never letterboxes), crops, prepends the cover with a short fade into gameplay, strips audio, and re-encodes with a higher CRF automatically if the file is over 50 MB:
   ```bash
   python scripts/make_preview.py make gameplay.mp4 \
     --cover-landscape cover_1920x1080.png \
     --cover-portrait cover_800x1200.png \
     --start 12.5 --duration 18 --out-dir out/
   ```
   Pass `--portrait-source gameplay_portrait.mp4` when a dedicated portrait recording exists. For landscape footage cropped to portrait, `--crop-focus 0.0-1.0` chooses which horizontal slice to keep (0 = left, 0.5 = center, 1 = right); check where the action is before accepting the default.

5. **Validate**, always, before handing over:
   ```bash
   python scripts/make_preview.py check out/preview_landscape.mp4 out/preview_portrait.mp4
   ```
   It verifies resolution, duration, audio, size, and warns about black bars and black frames. It cannot see the mouse cursor or burned-in text, so also scrub through the video yourself (extract frames with ffmpeg and look at them) for a cursor, UI overlays, "Play Now" text and misleading content.

6. **Deliver** the two files, state the checks that passed, and call out anything the user must judge (for example a portrait crop that cuts off the action, or a cover whose style clashes with the footage).

## Rules of thumb

- Never stretch to fit an aspect ratio; scale to cover and crop. Black bars are an explicit rejection reason.
- Do not speed footage up to cram more in. If the best moment is too long, cut a tighter one.
- Do not add text, logos, store badges or calls to action. The cover already carries the title.
- If the user supplies a longer recording, propose 2-3 candidate start times, make the best one, and offer alternates instead of asking for permission first.
- Keep the first second visually strong; hover previews are glanced at, not watched.
