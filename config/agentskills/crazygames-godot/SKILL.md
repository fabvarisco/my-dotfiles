---
name: crazygames-godot
description: >-
  Integrate the official CrazyGames Godot 4 addon and take a Godot game through
  Basic Launch, then Full Launch when CrazyGames selects it. Covers install,
  init, environment guards, gameplay start/stop, gated video ads and banners,
  user, data, invite links, and the Web export check. Use when a Godot 4 project
  targets CrazyGames, mentions the CrazyGames SDK or CrazySDK addon, basic
  launch, full launch, midgame or rewarded ads, cloud save, or an integration
  rejection. For iframe readability, physics, and the one-click rule, use
  crazygames-gameplay-check. For store art, use crazygames-cover and
  crazygames-preview-video.
---

# CrazyGames Godot 4

Two stages, one integration. Basic Launch ships with the SDK wired and ads off. Full Launch turns ads on and adds the modules the game actually needs. Do not rip the integration out between stages.

CrazyGames rejects a Basic Launch build that freezes when an ad call returns nothing, and a Full Launch build whose rewarded button does nothing. The flag below is what keeps both reviews happy.

Visual QA, covers, and the hover video are other skills. This one stops at the SDK and the export.

## Where to look

- [references/api.md](references/api.md) — Godot 4 method names, signals, error codes, and calls that do not exist. Read it before writing any `CrazyGames` call. Never invent a signature.
- If `res://addons/crazygames` is already in the project, open the `.gd` the call lives in and branch on that return type. The addon wins when it disagrees with the reference. If a name looks stale, fetch the doc URL listed in the reference.

Godot 3 (`yield` and the `JavaScript` singleton) is out of scope. If `project.godot` has `config_version=4`, say so and stop.

## Before writing code

1. Read `project.godot`. Note the main scene, autoloads, and whether `res://addons/crazygames` exists.
2. Find pause, the audio bus, save/load, and every playing vs not-playing screen (menu, pause, game over, level end).
3. Use the stage the user named. If they did not name one, treat a game that is not live yet as Basic Launch.
4. Leaderboards and in-game purchases are invite-only. Do not add them unless the user says the Developer Portal already enabled them.

## Install

1. Download the official CrazySDK addon (Godot Asset Library, publisher CrazyGames). Use the Godot 4 package, folder `crazysdk-godot-4`.
2. Copy that folder to `res://addons/crazygames`. Enabling the plugin registers its autoloads. Do not also autoload a second copy from `res://addons/crazysdk-godot-4`.
3. Enable it in Project Settings, Plugins. The plugin line belongs in `project.godot` under `[editor_plugins]`.
4. The first SDK call in game code is `await CrazyGames.is_initialised_async()`. On a non-Web export the addon marks itself initialised immediately, so this await must not hang the editor.
5. Export with the CrazyGames preset the addon adds. Rename the exported HTML to `index.html`. Serve it on `localhost` or `127.0.0.1`. Anywhere else the environment is `disabled` and every call throws. Force local mode on another host with `?useLocalSdk=true`.

## One wrapper, one flag

Keep SDK calls in one autoload the game owns, loaded after the addon autoloads. Every public method returns immediately unless init finished and `CrazyGamesBridge.get_environment()` is `local` or `crazygames`. The game stays playable in the editor, on itch.io, and on a disabled domain.

```gdscript
const ADS_ENABLED := false  # false on Basic Launch. Full Launch flips this.

func _ready() -> void:
    if not _sdk_present():
        return
    await CrazyGames.is_initialised_async()
    var settings: Dictionary = CrazyGames.Game.get_game_settings()
    if bool(settings.get("muteAudio", false)):
        _apply_platform_mute(true)
    if bool(settings.get("disableChat", false)):
        _apply_disable_chat()
```

`muteAudio` overrides any in-game mute toggle. If the installed addon exposes a settings-changed signal, connect it. Do not invent `add_settings_change_listener`.

Ads:

```gdscript
func request_midgame() -> void:
    if not ADS_ENABLED or not _sdk_live():
        return
    await _request_ad("midgame")

func request_rewarded() -> bool:
    if not ADS_ENABLED or not _sdk_live():
        return false
    return await _request_ad("rewarded")
```

`_request_ad` awaits `CrazyGames.Ad.request_ad_async`. Mute and pause on `CrazyGamesBridge.callbacks.ad_started` only, never at the request. Unmute and resume on `ad_finished` and on `ad_error`, latched so a double signal cannot advance twice. Grant a reward only when the addon’s return value is the finished state. Open the Ad script and match that type. Docs describe it as the `"finished"` state or an error payload, and third-party snippets disagree on whether that is a string or a dictionary.

During Basic Launch, hide rewarded buttons. A button that calls the SDK and then does nothing fails review. `adsDisabled` is the normal error while ads are switched off (also kids mode, and offline except rewarded).

## Basic Launch

SDK is optional on the platform. This skill still installs it, because Full Launch should be a flag flip plus the extra modules, not a second integration. Ads stay off.

Required when the SDK is in the build:

- `CrazyGames.Game.gameplay_start()` the moment the player can play. Not on the studio logo, not on the title screen. That first call is how CrazyGames measures the initial download.
- The game advances with `ADS_ENABLED` false. No freeze between levels, no rewarded button on screen.
- No external ad network, no Facebook/Google/email login, no in-game fullscreen button. CrazyGames provides fullscreen. Do not bind a required action to `Escape` on Web. It leaves fullscreen.
- Limits: initial download ≤ 50 MB, ≤ 20 MB to be eligible for the mobile homepage, total ≤ 250 MB, ≤ 1500 files, relative paths only. With the SDK integrated, initial size is measured until the first `gameplay_start`. Without the SDK, the whole build must be ≤ 50 MB.

`gameplay_stop`, banners, the Data module, and the User module can wait, unless the game already has accounts or cloud progress that would break without them. If it does, implement that module now and still leave ads off.

## Full Launch

Keep the Basic wiring. Then:

- Pair `gameplay_stop()` with every break: pause, menu, game over, level end, revive prompt. Call `gameplay_start()` again when play resumes. Do not call `gameplay_stop` when the tab blurs. Walk menu, level, win, menu, death and confirm the calls alternate.
- Set `ADS_ENABLED` to true. Midgame only at a real break (level change, stage clear). Never on the death-retry button, never on a menu or shop click. Rewarded is opt-in, has a path that does not watch an ad, shows a video icon, and is not chained. Handle `unfilled`, `adblock`, `adCooldown`, and `adsDisabled` by continuing play. `CrazyGames.has_adblock` may gate bonus content only. The game itself stays playable.
- Banners only through `res://addons/crazygames/Utils/crazy_banner.tscn`, on a surface that stays up, then `CrazyGames.Ad.refresh_banners()`. Not during active play.
- Progress: `CrazyGames.Data` is the only save on CrazyGames. Turn on Progress Save in the submission form or every call fails with `dataModuleDisabled`. Read a key before writing it. Migrate any existing browser save once.
- Accounts, only if the game has users: guests play by default. `get_user_async()` null means guest. A CrazyGames login button is allowed and must not be the main call to action. No other login providers. Listen on `auth_listener_complete` for a guest who logs in mid-session. Verify `get_user_token_async()` on the server. Never trust `__dangerousUserId`. Language comes from `CrazyGamesBridge.get_system_info()` `locale`, fallback English.
- `CrazyGames.Game.happy_time()` only for a real milestone (boss, personal best). Not on every level clear.
- New players reach gameplay in at most one click. That rule is Full Launch only. Check it with the crazygames-gameplay-check skill.

Multiplayer, only if the game has rooms: Godot can build an invite URL (`request_invite_url`, `get_invite_link_param`, `copy_to_clipboard`). `updateRoom`, instant multiplayer, and the friends list are not in the Godot addon. Do not stub them. `show_invite_button` is deprecated.

## Do not call

These show up in blog posts and are absent from the Godot 4 docs. They fail or no-op.

- `loading_start` / `loading_stop` — the export already covers load time
- `happytime()` — the method is `happy_time()`
- `set_game_context` / `clear_game_context` / `report_game_completed_percentage`
- `CrazyGames.Banner.request_banner` — use the `CrazyBanner` scene
- `CrazyGames.User.get_system_info()` — system info is on `CrazyGamesBridge`
- `CrazyGames.User.get_user()` without `_async`
- `list_friends`, `update_room`, `is_instant_multiplayer`

## Validate before saying it is done

1. Diff every new call against [references/api.md](references/api.md) and the addon source.
2. Search the project, excluding `addons/crazygames`, for `happytime(`, `set_game_context`, `loading_start`, `Banner.request_banner`, `User.get_system_info`, and `gameplay_stop` inside a focus or notification handler. `CrazyGamesBridge.get_system_info()` is the correct call and should stay.
3. Confirm `gameplay_start` sits on the first playable state, and that with `ADS_ENABLED` false no rewarded control is visible and no ad method runs.
4. Export with the CrazyGames preset, rename to `index.html`, serve on localhost. The console environment is `local`. Demo ads are an overlay, not a real video. Play a level and leave it. The game must resume.
5. Report what you did not run. A missing export is not a pass.

Store images and the hover clip are crazygames-cover and crazygames-preview-video. Iframe sizes, refresh rate, keys, and the one-click count are crazygames-gameplay-check.

## When CrazyGames picks the game up

Flip `ADS_ENABLED` to true, add the Full Launch calls this game is missing, and run the same validation with the flag on. Both ad endings have to resume. Then run crazygames-gameplay-check for the one-click rule.
