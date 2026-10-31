# CrazyGames Game Covers - Detailed Technical Specifications

Source: [CrazyGames Documentation - Game Covers](https://docs.crazygames.com/requirements/game-covers/#cover-images)

## 1. Technical Dimension Matrix

| Asset Name | Ratio | Exact Width | Exact Height | Recommended Format | Max File Size | Target Context |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `cover-landscape.png` | 16:9 | 1920 px | 1080 px | PNG / JPG (Quality > 90) | < 3 MB | Desktop category grid, featured banners |
| `cover-portrait.png` | 2:3 | 800 px | 1200 px | PNG / JPG (Quality > 90) | < 2 MB | Mobile feeds, vertical browsing grid |
| `cover-square.png` | 1:1 | 800 px | 800 px | PNG / JPG (Quality > 90) | < 1.5 MB | Tile cards, quick search, recommendations |

---

## 2. Safe Margins & Composition Guides

To avoid issues where rounded corners or responsive UI elements partially obscure important parts:

### Landscape (1920 x 1080)
* **Safe Zone**: 1720 x 940 px (centered, 100px horizontal padding, 70px vertical padding).
* **Focal Point**: 
  - Hero subject at horizontal center or rule-of-thirds (e.g. left 35% or right 65%).
  - Game title placed where it does not overlap the hero character's face.

### Portrait (800 x 1200)
* **Safe Zone**: 700 x 1060 px (centered, 50px horizontal padding, 70px vertical padding).
* **Focal Point**:
  - Vertical character stance, weapon, vehicle, or action reaching top-to-bottom.
  - Game title positioned in top 25% or bottom 20%.

### Square (800 x 800)
* **Safe Zone**: 700 x 700 px (centered, 50px padding all around).
* **Focal Point**:
  - Tightly framed character headshot or iconic game object.
  - Bold, easily readable title.

---

## 3. Pre-Submission Compliance Checklist

Run through this checklist before submitting covers to CrazyGames:

- [ ] **Exact Dimensions**:
  - Landscape is exactly 1920 x 1080 px.
  - Portrait is exactly 800 x 1200 px.
  - Square is exactly 800 x 800 px.
- [ ] **No Borders**: 
  - No black, white, or colored borders/frames outlining the image.
- [ ] **Text Compliance**:
  - Game title is present.
  - No extraneous words ("Play Now", "New", "Free", "Updated", "3D", "Multiplayer", version numbers, URLs).
- [ ] **Graphics Compliance**:
  - No App Store / Google Play / Steam badges.
  - No review scores or star ratings.
  - No watermarks or mouse cursors.
- [ ] **Visual Consistency**:
  - Same character, color grading, and logo style across all 3 assets.
- [ ] **Preview Video Sync**:
  - Static cover is identical to the first frame of the preview video.
