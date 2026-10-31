# CrazyGames approval requirements and quality guidelines

The submission bar, as opposed to the SDK API surface (that lives in
`sdk-v3.md`). Sourced from `docs.crazygames.com/requirements/*` — the
`intro`, `technical`, `gameplay`, `ads`, `account-integration` and `quality`
pages. Re-read those directly before a submission to confirm numeric limits,
which change more often than the principles.

## Contents

- [Mandatory integration checklist](#mandatory-integration-checklist)
- [Gameplay entry](#gameplay-entry)
- [Onboarding](#onboarding)
- [Quality guidelines](#quality-guidelines)
- [Restricted keys](#restricted-keys)
- [Launch stages](#launch-stages)
- [Reading a rejection](#reading-a-rejection)

## Mandatory integration checklist

- `loadingStart()` / `loadingStop()` called around **actual** loading.
- `gameplayStart()` / `gameplayStop()` on every playing ⇄ not-playing transition.
- Ads mute + pause on `adStarted`; unmute + resume on `adFinished` **and**
  `adError`.
- `game.settings.muteAudio` respected, taking priority over any in-game toggle.
- Game stays 100% playable with an adblocker active — only bonus content may be
  gated.
- Game does not crash when `environment === "disabled"`, if it is also published
  outside CrazyGames.
- "Progress Save" enabled on the Developer Portal if the game uses the data
  module.
- Guest play always available; never force login.

## Gameplay entry

> Games should land new users in gameplay immediately. If this is not feasible
> given the game specifics, a maximum of 1 click is allowed.

Cut long intros. For externally hosted or loaded files, QA evaluates against
**time to reach gameplay of 20 seconds or less**.

This is a structural requirement, not a nicety — a title screen plus a mode
select plus a level picker is three clicks and will be marked down. Games with
progression should resume the player's current level on boot and keep the menu
behind a button.

## Onboarding

- Provide a simple onboarding phase where new users land directly.
  - Implement the onboarding **in gameplay**.
  - Focus on core functionality; do not explain every feature.
  - Make it **skippable**.
- Prioritise **visuals** and limit the use of text.
- Show the user how to control the game with a **keyboard overlay or mouse
  gestures**.
- Make sure the UI is clear:
  - Buttons clearly labelled to indicate how to proceed.
  - Buttons not sized to encourage ads or other behaviours.
  - Buttons without delays that confuse users or encourage other behaviours.

## Quality guidelines

These are guidelines rather than hard requirements, but "overall quality" is the
most common rejection reason, and this is the page it refers to.

**General principles**
- Clear goals the player can reach.
- Easy to learn.
- Easy to understand — correct and clear language, well translated, or good use
  of universal graphic prompts.
- Controls consistent and intuitive throughout.

**A fun experience**
- Responds quickly to the player's actions.
- Challenge, strategy and pacing balanced.
- Display layout comfortable and intuitive.
- Audio comfortable and appropriate.
- Interface designed for the user's device (desktop, and optionally mobile).
- Enjoyable across player segments.
- No overly repetitive or boring tasks.
- Processes information quickly, giving a feeling of smooth flow.
- If both solo and social play exist, solo is as prominent; if solo is
  unavailable, the game says so clearly.

**Uniqueness**
- Easy to extend with new content — levels, art, story.
- Genre should not change after submission.
- Maintained and updated.
- **Not easily confused with another game of similar name or iconography.**
- No common identifier unless the developer owns the IP ("Super Chess" is fine,
  "Chess" is not; "Scrabble" only by the rights holder).

**Aesthetics**
- High quality, high resolution graphics; consistent resolution throughout; free
  of defects like compression artifacts.
- Audio levels consistent; sounds neither too loud nor too quiet; music
  complements the visuals.
- Internally consistent and coherent — the aesthetic should not switch between
  looks (realistic to cartoony, high to low resolution).
- **Clear about what it is and not misleading.** The name and imagery on
  CrazyGames must accurately reflect the type of game the player will
  experience, and should change only when genuinely necessary, such as a
  significant update or visual overhaul.
- Text and images legible across device sizes and responsive iframe sizes.

The legibility bullet is judged at `devicePixelRatio: 1` in a small 16:9 iframe.
Anything under roughly 12px is a risk.

The "not easily confused" and "not misleading" bullets bear on store art as much
as on the build: lead with whatever is genuinely distinctive about the game, and
show gameplay rather than decorative screens. If a mode resembles a well-known
genre staple, do not make it the cover.

## Restricted keys

- Controls should be intuitive and easy to learn.
- Prefer key bindings that adapt to the user's keyboard layout over asking the
  user to rebind. In France and elsewhere the standard layout is `AZERTY`, where
  the usual `WASD` movement keys sit at `ZQSD`.
- Avoid common keys with other behaviour on the web:
  - `Escape` closes fullscreen.
  - `Ctrl / Cmd + W` closes the tab — can be disabled only in fullscreen.

## Launch stages

New games publish under **Basic Launch**: limited distribution, and **ads are
not served**. Progression to a full launch depends on engagement metrics —
average playtime, conversion to gameplay, retention.

Two consequences for the build:

- Do not request ads while on Basic Launch, and do not show reward buttons that
  cannot fill. Gate the integration behind a config flag rather than deleting
  it, so review can still see it and enabling it later is one line.
- The metrics that decide promotion are the same ones the entry and onboarding
  requirements protect. Time-to-gameplay is measured against the first
  `gameplayStart()`, which makes correct lifecycle signalling a business
  concern, not just a compliance one.

## Reading a rejection

The rejection email states one reason and then lists common causes — low
gameplay quality, broken builds, copyright issues, integration requirements.
**That list is template boilerplate**, present in every rejection regardless of
cause. Only the stated reason is a signal about the specific game.

A useful response separates the verifiable from the subjective:

- **Verifiable**: click count to gameplay, missing or commented-out SDK calls,
  unpaired lifecycle signals, leaked render loops, bundle weight, font sizes,
  dead UI, store copy that promises absent features, third-party assets actually
  present in the repo. Fix all of these and say what was measured.
- **Subjective**: art direction, "is this fun", perceived production value. Be
  straight that these are judgement calls, and separate advice about them from
  the concrete fixes.

Checking copyright takes minutes — look for bundled fonts, images, audio and
third-party code — and the answer is usually that there is nothing to fix. Say
so rather than leaving someone worrying about it.
