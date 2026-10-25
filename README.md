# Dotfiles

Fedora Sway session, with packages and configuration managed by Home Manager. The graphical session compositor is SwayFX from Nix. Noctalia draws the bar, the wallpaper, and the panel launcher. Vicinae is the application launcher and clipboard history.

Tested on Fedora 44 Sway with SDDM.

`home.nix` uses paths relative to itself (`./sway`, `./kitty`, `./noctalia`). Home Manager reads `~/.config/home-manager/home.nix`, so the whole repository lives in that directory.

## Installation

### 1. Fedora packages

The Sway spin already includes most of these. Install the ones the configuration calls by a fixed path:

```sh
sudo dnf install \
  sway swayidle swaylock sway-systemd sddm sddm-wayland-sway \
  lxqt-policykit brightnessctl playerctl xdg-user-dirs procps-ng \
  pipewire-pulseaudio pulseaudio-utils \
  nix rpm-build
```

Thunar is optional. `home.nix` installs the Tela grey dark icon theme for it.

### 2. `sway-config-nix` session

The package in `system/` installs `start-sway` and the Wayland session entry. It provides `sway-config`, replaces `sway-config-fedora`, and removes Waybar. Noctalia is the bar.

```sh
cd system
rpmbuild -bb \
  --define "_sourcedir $(pwd)" \
  --define "_rpmdir $(pwd)/rpm" \
  sway-config-nix.spec
sudo dnf install ./rpm/noarch/sway-config-nix-1-2.noarch.rpm
```

`start-sway` runs `~/.nix-profile/bin/sway` when that binary exists. Fedora's `/usr/bin/sway` stays on the system for the SDDM greeter.

This package does not install `/etc/sway/config`. Run the `home-manager switch` from section 4 before ending the current session.

`system/start-sway` is derived from the Fedora Sway SIG script, under the MIT license in `system/LICENSE`.

### 3. Nix and Home Manager

Fedora's `nix` package enables flakes and points `<nixpkgs>` at `flake:nixpkgs`. Log in again, or load the profile in the current shell:

```sh
source /etc/profile.d/nix.sh
```

Home Manager for this configuration is the one that tracks nixpkgs unstable (26.11-pre when this setup was written). `home.stateVersion` stays `"24.11"`. That value records the release the configuration was created on.

```sh
nix run nixpkgs#home-manager -- --version
```

### 4. Configuration and the first switch

```sh
git clone -b fedora/sway https://github.com/fabvarisco/my-dotfiles.git ~/Developer/my-dotfiles
ln -s ~/Developer/my-dotfiles ~/.config/home-manager
nix run nixpkgs#home-manager -- switch
```

If `~/.config/home-manager` already exists and is not this repository, move it aside before the `ln`. Files Home Manager would take over that are already in `$HOME` can be moved aside with `home-manager switch -b backup`.

The first switch downloads Cursor, Zen Browser, Noctalia, SwayFX, and the wallpapers. Cursor is unfree; `nixpkgs.config.allowUnfree` is already enabled in `home.nix`.

After the switch, `home-manager` is on `~/.nix-profile/bin`. Log out to SDDM and start the Sway session.

## Updating

`~/.config/home-manager` is this repository. Edit the files here, then apply them:

```sh
home-manager switch
```

`Super+Shift+c` reloads Sway. A new compositor binary, a change to `sway/environment`, or a systemd user unit needs a new login. Kitty and Thunar read their configuration when they start, so reopen those.

These files are created empty (or with the default pointer speed) and later switches leave them in place:

- `~/.config/sway/outputs` — monitors, written by `nwg-displays` (`Super+p`)
- `~/.config/sway/workspaces`
- `~/.config/sway/pointer.conf` — `pointer-accel 0.3` (from `-1.0` to `1.0`)

## Another user or laptop

Edit these before the first switch:

| File | What to change |
| --- | --- |
| `home.nix` | `home.username` and `home.homeDirectory` |
| `swaylock/config` | wallpaper path |
| `noctalia/config.toml` | `wallpaper.directory`, city, and coordinates |
| `sway/environment` | `TZ`, when it should not be `America/Sao_Paulo` |
| `sway/config.d/30-lid.conf` | internal display name, when it is not `eDP-1` (`swaymsg -t get_outputs`) |

Leave `home.stateVersion` at `"24.11"`.

## Key bindings

`Super` is the modifier. The rest follows the usual i3/Sway layout (focus on `hjkl`, workspaces on the number keys, `Super+Shift+e` to exit).

| Binding | Action |
| --- | --- |
| `Super+Enter` | Kitty |
| `Super+d` | Noctalia launcher |
| `Alt+Space` | Vicinae |
| `Super+v` | clipboard history |
| `Super+n` | control center |
| `Super+,` | Noctalia settings |
| `Super+p` | arrange monitors |
| `Super+Shift+s` | region screenshot |
| `Super+Print` | full-screen screenshot |
| `Super+Shift+c` | reload the configuration |
| `Super+q` | close the window |
