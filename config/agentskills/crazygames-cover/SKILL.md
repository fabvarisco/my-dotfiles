---
name: crazygames-cover
description: >-
  Use this skill whenever creating, adapting, designing, or validating cover images
  and preview video specifications for game submissions on CrazyGames, following official
  storefront requirements (1920x1080 landscape, 800x1200 portrait, 800x800 square, strict text & border rules).
---

# CrazyGames Game Covers Skill

This skill provides step-by-step instructions, automated validation scripts, and design standards to produce game cover assets that strictly adhere to [CrazyGames Game Covers Requirements](https://docs.crazygames.com/requirements/game-covers/#cover-images).

---

## 1. Mandatory Cover Image Formats & Specifications

CrazyGames requires **three distinct cover images** for every game submitted:

| Format | Aspect Ratio | Dimensions | Primary Use on CrazyGames |
| :--- | :--- | :--- | :--- |
| **Landscape** | **16:9** | **1920 x 1080 px** | Featured carousels, desktop category feeds, banner promos |
| **Portrait** | **2:3** | **800 x 1200 px** | Mobile storefront feeds, vertical discovery grids |
| **Square** | **1:1** | **800 x 800 px** | Compact listings, search results, related games tiles |

> [!IMPORTANT]
> All three formats must maintain **visual consistency** (identical art style, key characters/elements, color palette, and logo typography) so players immediately recognize the game across all layouts.

---

## 2. Platform Compliance Rules (Strict Do's & Don'ts)

CrazyGames acts as a fast-paced digital storefront. Submissions that violate these rules can be rejected during review:

### ✅ DO:
1. **Include Only the Game Title**: Feature the game name in a clean, legible, stylized typography matching the game's aesthetic.
2. **Design for Immediate Impact**: The core gameplay or fantasy must be understood within a fraction of a second while users scroll past hundreds of titles.
3. **Use Dedicated Artwork / Key Art**: Compose a focused scene with a prominent hero element or character. If using in-game renders, pose and light them professionally.
4. **Safe Margins**: Keep key visual subjects and the game title within the central safe area (at least 5-8% padding from edges) to prevent UI truncation.
5. **High Resolution & Clarity**: Ensure sharp, non-pixelated graphics exported in high quality (`.png` or top-quality `.jpg`).

### ❌ DO NOT:
1. **NO Borders or Frames**: Never add borders, frames, or decorative edges around the cover.
2. **NO Extra Text**: **Never** include call-to-action or promotional words such as `"Play"`, `"Play Now"`, `"New"`, `"Updated"`, `"Free"`, `"v1.2"`, or discount badges. The **only** allowed text is the official game title.
3. **NO Platform or Store Badges**: Do not include App Store, Google Play, Steam, or social media icons.
4. **NO Raw, Cluttered Screenshots**: Do not simply dump an unedited screenshot filled with HUD, chat boxes, debug text, or default mouse cursors.
5. **NO Watermarks or Third-Party Logos**: Avoid third-party branding, unowned copyright assets, or stock watermarks.

---

## 3. Companion Preview Video Rules

CrazyGames also requires preview videos alongside cover images:

* **Resolutions**: Full-screen Landscape (1080p, 16:9) and Portrait (1080p, 2:3).
* **Duration**: 15–20 seconds maximum (longer videos are automatically trimmed to 20s).
* **File Size**: Maximum 50 MB.
* **Audio**: **No sound** (must be silent).
* **Opening Frame**: **Crucial** — Use your static cover as the exact first frame of the preview video for seamless hover transitions.
* **Prohibited in Video**: Black frames, logo fade-ins, black bars (letterboxing), default mouse cursors, promotional text overlays.

---

## 4. End-to-End Workflow

When asked to produce or adapt CrazyGames covers:

### Step 1: Establish the Key Visual & Typography
1. Identify the core game hook (e.g., character, monster, vehicle, or central game mechanic).
2. Choose a clean, stylized typography for the game's title.
3. Keep the background atmospheric yet uncluttered so the foreground hero element and title pop.

### Step 2: Generate or Compose Assets
If generating images (via `image-generator` or prompt engineering):
* Generate an ultra-high-resolution master artwork (e.g., 2048x2048 or 16:9 base).
* Keep the main character and action centralized so it can be cropped and recomposed into 16:9, 2:3, and 1:1 without losing key details.
* Avoid baking text directly into initial AI image generation; composite clean vector or stylized typography on top.

### Step 3: Adapt to the 3 Formats
* **Landscape (1920x1080)**: Horizontal breathing room. Title can be placed top-center, bottom-center, or on one side balanced by the hero character.
* **Portrait (800x1200)**: Vertical orientation. Place the game title either at the top third or lower third, with the hero element filling the vertical space.
* **Square (800x800)**: Compact focus. Zoom in tighter on the hero element and place the title prominently.

### Step 4: Validate Assets
Run the automated validator script:
```bash
python scripts/validate_covers.py --dir /path/to/covers/
```
The script verifies exact pixel dimensions, aspect ratios, and format requirements.

---

## 5. References & Helper Scripts

* Detailed Specifications & Safety Margins: [specifications.md](./references/specifications.md)
* Automated Cover Image Validator: [validate_covers.py](./scripts/validate_covers.py)
* Automatic Template / Resizer Helper: [generate_covers.py](./scripts/generate_covers.py)
