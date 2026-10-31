---
name: crazygames-html5
description: Integrate the CrazyGames HTML5 SDK v3 into a web game and get that game through CrazyGames' submission review — ads, lifecycle signals, leaderboards, save data, plus the approval requirements and quality guidelines that actually decide acceptance. Use this whenever someone is building or shipping a JS/HTML5 game they intend to publish on CrazyGames, mentions the CrazyGames SDK, midgame or rewarded ads in a web game, is preparing a build for submission, or has had a game rejected and wants to know why. Also use it when auditing a web game for launch readiness on a game portal even if CrazyGames is not named, since the same requirements apply almost everywhere.
---

# Shipping a game on CrazyGames

Two different jobs live here, and they fail for different reasons.

**Integration** is mechanical: call the SDK correctly. Getting it wrong produces
review comments, but it is fixable and obvious.

**Approval** is where games actually die. CrazyGames rejects most often with a
single line — *"the overall quality of the game does not yet meet the
expectations of our platform"* — and nothing more. Their rejection email also
lists common reasons (copyright, broken builds, integration) as **boilerplate
template text**, not findings about the specific game. Read the stated reason as
the only real signal, and treat the boilerplate as a checklist rather than a
diagnosis. Telling someone to go hunt for copyright problems they don't have
wastes days.

So when someone arrives with a rejection, separate what is **objectively
verifiable** from what is subjective, fix all of the former, and be honest that
the latter is a judgement call.

## Where to look things up

- `references/sdk-v3.md` — exact method names, callback shapes and module
  surface for SDK v3. Read it before writing any `window.CrazyGames.SDK` call.
  Never invent a signature; if it looks stale, fetch the doc URLs it lists.
- `references/requirements.md` — the approval requirements and quality
  guidelines in full, plus the audit checklist. Read it when preparing a
  submission or diagnosing a rejection.

## The integration contracts

These are what review checks, and each one has a failure mode worth
understanding rather than memorising.

**Guard everything, so the game survives without the SDK.** Wrap every SDK call
in a helper that returns early unless init succeeded. The game must stay 100%
playable on itch.io, on localhost, on the developer's own domain, and when
`environment === 'disabled'`. Only bonus content may be gated behind ads.

**Nothing touches the SDK or the DOM at module-eval time.** Keeping SDK access
inside functions is what lets the module be imported by a Node smoke test, and
what stops a missing SDK from throwing during page load.

**`await cgInit()` before any other call.** Everything else is undefined
behaviour before that resolves.

**Ads always resume the game.** Mute and pause on `adStarted`; unmute and resume
on `adFinished` **and** on `adError`. The error path is the one people forget,
and it is exactly the path that strands a player behind a dead ad when there is
no fill. Latch the resume so a double callback cannot advance twice:

```js
export function withMidgameAd(advance){
  if (!CFG.ads.enabled) { advance(); return; }   // see launch stages below
  const wasMuted = A.muted;
  let ran = false;
  cgRequestMidgameAd(
    () => setMuted(true),
    () => { if (ran) return; ran = true; setMuted(wasMuted); advance(); },
  );
}
```

**Pair the lifecycle signals.** `gameplayStart`/`gameplayStop` on every
playing⇄not-playing transition — menu, level end, pause, revive, game over. Do
*not* call `gameplayStop` on tab blur; the platform handles that. Trace every
path by hand (menu → level → win → menu → other mode → death) and confirm they
alternate; a leaked `gameplayStart` skews their engagement metrics.

**`loadingStart`/`loadingStop` bracket real work**, and `loadingStop` comes
*before* the first `gameplayStart`. CrazyGames measures time-to-gameplay against
that first `gameplayStart`, so a pair of calls wrapped around a synchronous boot
measures nothing.

**Use `happytime` sparingly.** It is for genuine milestones — a world finished, a
personal best. Firing it on every level cleared is a documented misuse and reads
as noise.

**Platform mute wins.** Apply `game.settings.muteAudio` before anything plays and
subscribe to settings changes; it overrides any in-game toggle.

## Launch stages: ads may not be servable yet

CrazyGames publishes new games under **Basic Launch**, where ads are not served.
Requesting them anyway is pointless, and showing a "watch ad for a reward" button
that can never fill is worse than showing nothing.

Do not delete the integration — review still wants to see it, and you will want
it back. Gate it behind one config flag instead:

```js
// CFG.ads.enabled === false while on Basic Launch. The integration stays wired
// and reviewable; a full launch is a one-line change.
ads: { enabled: false, everyNStages: 5, everyNLevels: 4 },
```

Every ad call site and the rewarded button check that flag. Verify both
positions before shipping: with it off, nothing reaches the SDK and the game
still advances; with it on, both paths fire and resume correctly.

Place midgame ads at genuine breaks — a stage advance, between levels. Never on
the retry after a death, which is the most punishing possible moment.

## Reaching gameplay

This is the single most common structural rejection, and it is easy to miss
because it feels like good design to the person who built the menu.

**Land the player in gameplay immediately. One click maximum.** A title screen
plus a mode select plus a level grid is three, and it will be marked down. If the
game has progression, boot straight into the player's next unfinished level and
keep the menu one tap away on a button. If there is genuinely nothing to resume,
fall back to whatever mode is playable.

When collapsing menus, watch for a screen becoming unreachable or a path that
dead-ends: if the home button hides while a menu is open, that menu needs its own
way back to the board.

## Onboarding

Their guidance is specific, and a text toast satisfies none of it: onboarding
should happen **in gameplay**, lean on **visuals rather than text**, be
**skippable**, and **show the control** with a keyboard overlay or a mouse
gesture.

The pattern that satisfies all four at once: the first time a player meets each
mechanic, animate a ghost pointer performing the gesture on the real board, and
cancel it on their first input. Touching the board *is* the skip, so no skip
button is needed. Drive it from the render loop the game already has rather than
opening another one, and suppress it under `prefers-reduced-motion`.

If the game has keyboard shortcuts, surface them — bindings nobody can discover
may as well not exist. Avoid keys the browser owns (`Escape` exits fullscreen,
`Ctrl/Cmd+W` closes the tab), and remember `WASD` is `ZQSD` on AZERTY.

## Auditing a game before submission

Work through `references/requirements.md`, but these are the checks that most
often turn up something real. Each one comes from a shipped game that failed it.

1. **Are the ad call sites actually live?** Commented-out integrations are
   common — someone disabled ads for testing and never restored them. There is
   then nothing for review to assess.
2. **Is teardown ever called?** Lazily-created render loops, WebGL contexts and
   `requestAnimationFrame` callbacks routinely leak: a menu opened once keeps
   rendering for the whole session, through gameplay. Grep for the dispose
   function and check it has a caller.
3. **Is a heavy dependency doing a trivial job?** Shipping a 3D engine to stroke
   a handful of wireframe edges, in a game that is otherwise 2D canvas, is pure
   load time. Measure the bundle before and after removing it.
4. **Does the store copy match the build?** Descriptions promising leaderboards,
   ads or modes that are disabled violate their "not misleading" rule directly.
5. **Does the on-screen text match the on-screen art?** Hints that say "start at
   the ring" while the marker is a square confuse first-time players and are
   trivially fixable.
6. **Is anything decorative being read as a bug?** Randomised glyphs, scrambling
   text and placeholder-looking states read as rendering faults, especially on
   the first screen. If an effect never resolves, it is not an effect.
7. **Count the clicks** from load to the first frame of real play.
8. **Is any text below ~12px?** Legibility is judged at `devicePixelRatio: 1` in
   a small responsive iframe, not on your monitor.
9. **Is there dead UI?** Buttons wired to nothing, CSS for elements that no
   longer exist, handlers behind a debug flag documented as player controls.
10. **Copyright is usually a non-issue — verify rather than assume.** Check
    whether any third-party font, image, audio or code is actually bundled. If
    everything is procedural, say so plainly instead of sending someone on a
    hunt. Do watch genre-adjacent trademarks in *naming* (a Flow-like mode should
    not be sold as "Flow"), and ship the licence text for any bundled MIT code.

## Verifying, rather than asserting

Claims about a game's behaviour are cheap and often wrong. Where the environment
allows, drive the real build: run the dev server and use a headless browser to
count clicks to gameplay, confirm the ad callbacks resume the game on both
paths, check no render loop survives leaving the menu, and walk the flows that
the lifecycle signals are supposed to bracket. A screenshot or a state dump
settles questions that reading the source does not.

Measure the bundle with the project's own build before and after any dependency
change, and report the real numbers rather than estimates from `node_modules`
sizes — tree-shaking makes those wildly misleading.
