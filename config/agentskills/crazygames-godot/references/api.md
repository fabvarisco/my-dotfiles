# CrazyGames Godot 4 API

Signatures from the Godot 4 tabs on docs.crazygames.com. If the installed addon disagrees, trust the addon and refetch the URL. Do not invent overloads.

Godot 4 uses `JavaScriptBridge` and `await`. Signals are on `CrazyGamesBridge.callbacks`.

## Install and init

https://docs.crazygames.com/sdk/intro/#godot-4x

```gdscript
await CrazyGames.is_initialised_async()
var environment := CrazyGamesBridge.get_environment()
# "local" | "crazygames" | "disabled"
```

Copy `crazysdk-godot-4` to `res://addons/crazygames` and enable the plugin. Call nothing else until `is_initialised_async()` returns. On non-Web exports the addon marks itself initialised immediately.

`disabled` throws on every call. Guard on `local` or `crazygames`.

Local test: CrazyGames export preset, HTML renamed to `index.html`, HTTP server on `localhost` or `127.0.0.1`. `?useLocalSdk=true` forces local mode on another host. Local mode shows an overlay instead of video ads, logs SDK events, returns demo user data, and shows demo banners.

## Video ads

https://docs.crazygames.com/sdk/video-ads/

```gdscript
var result = await CrazyGames.Ad.request_ad_async("midgame") # or "rewarded"
var has_adblock = CrazyGames.has_adblock

CrazyGamesBridge.callbacks.ad_started.connect(_on_ad_started)
CrazyGamesBridge.callbacks.ad_finished.connect(_on_ad_finished)
CrazyGamesBridge.callbacks.ad_error.connect(_on_ad_error)
```

`result` is the `"finished"` state or an error payload. Read the Ad script in the addon before comparing it. Reward only on finished.

Pause and mute inside `ad_started`. Resume and unmute inside both `ad_finished` and `ad_error`. Muting at request time is wrong: an unfilled call would mute and unmute with nothing on screen.

Error `code` values:

| code | meaning |
|---|---|
| `adsDisabled` | no ads this session: Basic Launch, kids mode, or offline (rewarded can still be available offline). Replaces `adsDisabledBasicLaunch` |
| `unfilled` | no ad |
| `adblock` | blocker |
| `adCooldown` | too soon. Midgame is about one every 3 minutes, counting rewarded and preroll |
| `other` | anything else |

Shape: `{ "code": "unfilled", "message": "No ad available" }`.

The game must keep working with an ad blocker. Extra cosmetics or levels may be gated. Core play may not.

## Banners

https://docs.crazygames.com/sdk/banners/

Instance `res://addons/crazygames/Utils/crazy_banner.tscn`. Sizes the control maps to:

- `LEADERBOARD_728x90`
- `MEDIUM_300x250`
- `MOBILE_320x50`
- `MAIN_BANNER_468x60`
- `LARGE_MOBILE_320x100`

After showing or hiding overlays:

```gdscript
CrazyGames.Ad.refresh_banners()
```

There is no `CrazyGames.Banner` module in the Godot docs.

## Game

https://docs.crazygames.com/sdk/game/

```gdscript
var game_settings = CrazyGames.Game.get_game_settings()
CrazyGames.Game.gameplay_start()
CrazyGames.Game.gameplay_stop()
CrazyGames.Game.happy_time()
```

`get_game_settings()` carries `muteAudio` and `disableChat`. Local overrides: `?muteAudio=true`, `?disableChat=true`. Platform mute wins over the in-game toggle. The docs do not show a Godot settings-change listener. Use one only if the addon defines it.

`gameplay_start` on play and on every resume (start, revive, next level). The first call measures initial download, so it belongs on the playable state, not a menu.

`gameplay_stop` on every break (menu, level end, pause). Do not call it on focus loss. The platform does that.

`happy_time` is for a boss, a high score, a real milestone. Not for clearing a level or picking up an item.

Invite link (multiplayer):

```gdscript
var invite_url = CrazyGames.Game.request_invite_url({"roomId": "1234"})
CrazyGamesBridge.copy_to_clipboard(invite_url)
var room_id = CrazyGames.Game.get_invite_link_param("roomId")
```

Deprecated, still present:

```gdscript
var link = CrazyGames.Game.show_invite_button({"roomId": "1234"})
CrazyGames.Game.hide_invite_button()
```

Prefer the invite URL. Room data replaced the invite button on other engines, and room data is not in the Godot addon.

Not in the Godot 4 tab. Do not call:

- `loading_start` / `loading_stop` (the export reports loading)
- `set_game_context` / `clear_game_context`
- `report_game_completed_percentage`
- `update_room` / `left_room`
- `is_instant_multiplayer`
- join-room listener

## User

https://docs.crazygames.com/sdk/user/

```gdscript
var is_available = CrazyGames.User.is_user_account_available()
var user = await CrazyGames.User.get_user_async()          # null if guest
var token = await CrazyGames.User.get_user_token_async()
var prompted = await CrazyGames.User.show_auth_prompt_async()
var response = await CrazyGames.User.show_account_link_prompt_async()
var system_info = CrazyGamesBridge.get_system_info()

CrazyGamesBridge.callbacks.auth_listener_complete.connect(_on_auth)
func _on_auth(user: Dictionary) -> void:
    print(user.get("username", ""))
```

User dictionary:

```gdscript
# __dangerousUserId, username, profilePictureUrl
# username is 6-20 chars: letters, numbers, period, underscore
```

`__dangerousUserId` is client-controlled. Do not authenticate with it. Send `get_user_token_async()` to the server. The HTML5 API takes `{ signingKeyType: "IN_GAME_AUTH" }`. The Godot snippet takes no argument. If the addon accepts a signing key, pass `IN_GAME_AUTH` and verify with the JWKS at `https://userportal.crazygames.com/.well-known/jwks.json`. Token lifetime is 1 hour. The SDK refreshes it. Do not cache it, and do not verify it in the client.

`system_info` fields used in practice: `locale` (language, fallback English), `countryCode`, `device.type` (`desktop`, `tablet`, `mobile`), `os`, `browser`, `applicationType` (`web`, `pwa`, `google_play_store`, `apple_store`).

`show_account_link_prompt_async` returns `{ "response": "yes" }` or `{ "response": "no" }`.

Auth prompt errors: `showAuthPromptInProgress`, `userAlreadySignedIn`, `userCancelled`.

Account-link errors: `showAccountLinkPromptInProgress`, `userNotAuthenticated`.

Token errors: `userNotAuthenticated`, `unexpectedError`.

Logout reloads the page. The auth listener does not fire for logout. It fires when a guest logs in. If progress lives in the Data module, the platform reloads on login. If progress lives on your server, reload that user's data from the listener.

`list_friends` is not in the Godot addon.

Local user query params (append to the localhost URL):

| param | values |
|---|---|
| `user_account_available` | `false` (default true) |
| `show_auth_prompt_response` | `user1`, `user2`, `user_cancelled` |
| `link_account_response` | `yes`, `no`, `logged_out` |
| `user_response` | `user1`, `user2`, `logged_out` |
| `token_response` | `user1`, `user2`, `expired_token`, `logged_out` |

Defaults: `get_user` returns `user1`, token is `user1`'s, account link returns `yes`, auth prompt returns `user1`.

## Data

https://docs.crazygames.com/sdk/data/

```gdscript
CrazyGames.Data.data_set_item("gold", "100")
var gold := 0
if CrazyGames.Data.data_has_key("gold"):
    gold = int(CrazyGames.Data.data_get_item("gold"))
```

Values are strings. Init first. The SDK preloads cloud data during init, so await init on the load screen, not on the first save.

On CrazyGames this module is the only save, for guests and for logged-in players. A second local save fights it. Guests land in `localStorage`. Login copies guest data up if the account has none, or loads the account data if it has some. Logout returns to the guest blob. The SDK does this. Game code does not.

Enable "Yes, using the Data Module from the CrazyGames SDK" in the submission form.

Errors:

| code | meaning |
|---|---|
| `dataLimitExcedeed` | JSON of all keys exceeded 1 MB. The write was dropped. Spelling is the API's |
| `dataModuleDisabled` | Progress Save toggle is off |
| `other` | anything else |

Writes debounce about 1 second, sometimes up to 30. Read a key before writing it so a stale client cannot wipe progress. If the game already shipped with browser saves, copy those keys in once.

Remove and clear exist on the HTML5 module (`removeItem`, `clear`). Call them on Godot only under the names the addon script defines.

## Purchases and leaderboards

Invite-only. Confirm the portal enabled them before writing code.

Purchases, when invited: https://docs.crazygames.com/sdk/in-game-purchases/

```gdscript
var order := {
    "orderId": "example-order-id",
    "status": "done",
}
CrazyGamesBridge.analytics_track_order("xsolla", order)
```

Call that when the Xsolla order status is `done`. A real Xsolla token exists only on the preview tool (`crazygames.com/preview`), not on localhost.

Leaderboards: https://docs.crazygames.com/sdk/leaderboards/ — one board per game, portal encryption key required for client submits. Read the Godot tab of the leaderboards SDK page before calling anything. Do not guess the method names.

## Requirements that change the integration

https://docs.crazygames.com/requirements/intro/
https://docs.crazygames.com/requirements/technical/
https://docs.crazygames.com/requirements/ads/
https://docs.crazygames.com/requirements/account-integration/
https://docs.crazygames.com/resources/basic-launch-metrics/

Basic Launch: SDK optional, ads disabled even if integrated. If the SDK is in the build, `gameplay_start` is required and the game must run while ads are disabled. QA checks that. No external ads, no external login, no custom fullscreen button.

Size: initial download ≤ 50 MB (≤ 20 MB for the mobile homepage), total ≤ 250 MB, ≤ 1500 files, relative paths only. With the SDK, initial size is the bytes until the first `gameplay_start`. Without it, the whole build is the initial size and must be ≤ 50 MB. External files are judged by time-to-gameplay, about 20 seconds.

Full Launch adds `gameplay_stop`, ads through this SDK that survive adblock, Data when the game has progress, User when the game has accounts, and landing in gameplay in at most one click.

Basic Launch window: at least 7 days and 500 plays, or 21 days if 500 plays never arrive. Strong titles are around 10+ minutes average play, 10-15% day-1 retention, 80%+ conversion (play at least a minute), load under about 10 seconds, build under 20 MB. Those are targets, not a checklist the SDK can satisfy by itself.
