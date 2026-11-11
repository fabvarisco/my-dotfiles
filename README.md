# my-dotfiles

Dotfiles repository. Each system lives on its own branch.

## Windows

`windows/glazewm-yasb` — Windows 11 tiling desktop: GlazeWM, YASB, Starship, and Fastfetch.

```powershell
git clone -b windows/glazewm-yasb https://github.com/fabvarisco/my-dotfiles
```

## Fedora

`fedora/sway` — Fedora Sway session managed by Home Manager. SwayFX is the compositor, Noctalia draws the bar, and Vicinae is the launcher. Tested on Fedora 44.

```sh
git clone -b fedora/sway https://github.com/fabvarisco/my-dotfiles
```

## NixOS

`nixos/hyprland` — NixOS flake for the Beelink machine: Hyprland, Noctalia, Vicinae, and SilentSDDM. Configuration `beelink-hypr`, user `fabvarisco`.

```sh
git clone -b nixos/hyprland https://github.com/fabvarisco/my-dotfiles
```

## WSL

`wsl/ubuntu-nix` — Ubuntu 26.04 on WSL2 with Determinate Nix, a standalone home-manager flake, and devenv per project.

```sh
git clone -b wsl/ubuntu-nix https://github.com/fabvarisco/my-dotfiles
```
