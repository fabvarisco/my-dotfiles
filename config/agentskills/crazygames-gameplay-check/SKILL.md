---
name: crazygames-gameplay-check
description: Audit a web game against the CrazyGames Gameplay requirements before submission and produce a pass/fail/review report with fixes. Covers readability at the 10 official iframe sizes, consistent physics across refresh rates, English localization and SDK locale, restricted keys and keyboard layouts, load errors and crashes, custom fullscreen buttons, cross-promotion and store links, PEGI 12 suitability, and landing in gameplay within one click. Use this skill whenever the user wants to validate, QA, pre-check or "see if CrazyGames will accept" a game, asks why CrazyGames rejected a game on gameplay or quality grounds, or asks about any of those individual rules, even if they never say "gameplay requirements".
compatibility: Python 3 for the static audit. The viewport check needs Playwright (Python) with Chromium and, optionally, Pillow.
---

# CrazyGames gameplay check

CrazyGames reviewers run visual and functional checks on every submission, and developers who repeatedly submit non-compliant games can be restricted. This skill finds the problems first. It combines automated checks (code scan, screenshots, console errors) with a manual checklist, because several rules (readability, PEGI 12, originality) need human or visual judgment and no script can decide them.

Sources: https://docs.crazygames.com/requirements/gameplay/ and the Quality page (restricted keys). Rules can change; if the user reports a different requirement, trust them and re-check those pages.

## Basic vs Full launch

Ask which stage applies only if it is not obvious. Basic launch needs everything below except the last row of the table. Full launch (after CrazyGames selects the game) also requires landing new players directly in gameplay, with at most 1 click.

## The requirements and how to check each

| Requirement | How |
|---|---|
| **Readable content**: text and images legible at devicePixelRatio 1 on the official sizes (and mobile if the game supports it) | `viewport_check.py` screenshots, then look at them |
| **Consistent physics** at 144/165 Hz, not only 60 Hz | `static_audit.py` heuristic, plus `viewport_check.py --raf-hz` runs |
| **English localization**; translations accurate; language from SDK `systemInfo.locale`, fallback English | `static_audit.py` presence check, then read the strings |
| **Intuitive controls**, avoid restricted keys (`Escape` exits fullscreen, `Ctrl/Cmd+W` closes the tab), keys adapt to the keyboard layout (AZERTY has ZQSD) | `static_audit.py` flags, then judge |
| **Smooth performance**: loads fast, no errors or crashes | `viewport_check.py` reports console errors, page errors, failed requests, load time |
| **Originality** of name, assets, content | Manual |
| **No custom fullscreen button**; CrazyGames provides fullscreen and custom buttons can break monetization | `static_audit.py` |
| **No cross-promotion** (details below) | `static_audit.py`, then judge each hit |
| **Suited for minors**: audience is 13+, game must be PEGI 12 compliant | Manual, see checklist |
| **Full launch only**: lands in gameplay immediately, max 1 click | `viewport_check.py --click-center` screenshots |

Cross-promotion rules, since the verdict depends on context: privacy policy and terms links are fine. Allowed if they are not the main call to action on the menu: community links (Discord, dev site) that do not lead to a playable web version; Steam/Epic links on desktop games only on the main menu or at the end of a demo; backlinks to the CrazyGames home or category pages; links to other games in the same series. App Store and Google Play links are never allowed in-game (use the metadata fields in the Developer Portal). Anything else promoting other games or platforms is a violation.

## Workflow

1. **Locate the game.** Prefer the source project for Godot and Unity (their web exports are mostly wasm/pck files, so a code scan of the export finds nothing). For plain HTML5/JS, scanning the build folder works.
2. **Static audit:**
   ```bash
   python scripts/static_audit.py <project_or_build_dir>
   ```
   Output has `FAIL` (clear violation), `REVIEW` (suspicious, open the file and decide) and `INFO` lines. Always open the flagged lines before reporting; a regex hit is evidence, not a verdict. Add `--json` for machine-readable output.
3. **Run the game and capture it.** Serve the build locally (`python -m http.server` inside the build folder) and run:
   ```bash
   python scripts/viewport_check.py http://localhost:8000/ --out-dir shots/ --wait 6
   python scripts/viewport_check.py http://localhost:8000/ --out-dir shots_144/ --raf-hz 144
   python scripts/viewport_check.py http://localhost:8000/ --out-dir shots_click/ --click-center
   ```
   Open `shots/contact_sheet.png` for the overview, then the individual screenshots for any size where text, HUD or buttons look small, clipped, overlapping or off-screen. Compare `shots/` against `shots_144/` for the same wait time: with a game that behaves the same at every refresh rate, progress such as scrolling speed or timers should look equivalent. A clear difference suggests frame-rate-dependent logic. `--raf-hz` only emulates `requestAnimationFrame` cadence, which covers HTML5 and Godot/Unity web builds but not logic driven by something else.
4. **Manual checklist** for what automation cannot judge (use the screenshots where possible):
   - Text and icons are readable at 800x450 and 907x510, the smallest sizes.
   - Content, names and art are original, with no ripped assets or confusable names (a generic name like "Chess" is a problem).
   - PEGI 12: no graphic gore or realistic violence, no sexual content, no strong language, no realistic gambling, no drug promotion, no frightening content beyond mild. When unsure, mark REVIEW and say what to change.
   - Translations read naturally (not machine-garbled) and the language switches by SDK locale, with English fallback.
   - Controls are explained (keyboard overlay or mouse hint), consistent across screens, and playable on touch if mobile is claimed.
5. **Report.** Give one line per requirement: PASS, FAIL, REVIEW or NOT CHECKED, with file:line or screenshot as evidence and a concrete fix for every FAIL and REVIEW. Lead with the failures. Be explicit about what was not verified (for example "PEGI 12 not confirmed, only code scanned"), because a false all-clear is worse than a short list of unknowns.

## Fix patterns worth suggesting

- Fullscreen: delete the in-game button and any `requestFullscreen` call; CrazyGames supplies fullscreen.
- Keys: bind movement by physical key (`event.code`, so WASD works as ZQSD on AZERTY) and show hints from the user's layout (`navigator.keyboard.getLayoutMap()`) rather than hard-coded letters. Do not make `Escape` required for core actions; it exits fullscreen.
- Physics: scale per-frame movement by the frame delta, or run simulation on a fixed timestep (Godot `_physics_process`, Unity `FixedUpdate`, an accumulator loop in JS).
- Locale: read `systemInfo.locale` from the CrazyGames SDK, map it to a supported language, fall back to English.
- Store links: remove App Store/Google Play links from the game and put them in the Developer Portal metadata.
