# Windows GlazeWM + YASB

Dotfiles for a tiling desktop on Windows 11: GlazeWM, YASB, Starship, and Fastfetch. Window borders from GlazeWM need Windows 11.

Two files still point at `C:\Users\fabri`: `profile powershell` and `.config/fastfetch/config.jsonc`. After copying, change that path to your own user folder.

## Install the programs

```powershell
winget install --id glzr-io.GlazeWM -e
winget install --id amnweb.YASB -e
winget install --id Starship.Starship -e
winget install --id fastfetch-cli.Fastfetch -e
winget install --id Microsoft.PowerShell -e
```

The bar and the prompt use JetBrainsMono Nerd Font (`JetBrainsMono NFP`). Install that font and restart the terminal. YASB icons also use Segoe Fluent Icons, which ships with Windows 11.

## Install the config

```powershell
git clone -b windows/glazewm-yasb https://github.com/fabvarisco/my-dotfiles.git $env:USERPROFILE\Developer\my-dotfiles
cd $env:USERPROFILE\Developer\my-dotfiles

New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config" | Out-Null
New-Item -ItemType SymbolicLink -Force -Path "$env:USERPROFILE\.config\fastfetch" -Target "$PWD\.config\fastfetch"
New-Item -ItemType SymbolicLink -Force -Path "$env:USERPROFILE\.config\yasb" -Target "$PWD\.config\yasb"
New-Item -ItemType SymbolicLink -Force -Path "$env:USERPROFILE\.config\starship.toml" -Target "$PWD\.config\starship.toml"
New-Item -ItemType SymbolicLink -Force -Path "$env:USERPROFILE\.glzr" -Target "$PWD\.glzr"

New-Item -ItemType Directory -Force -Path (Split-Path $PROFILE) | Out-Null
New-Item -ItemType SymbolicLink -Force -Path $PROFILE -Target "$PWD\profile powershell"
```

Creating those links needs a terminal allowed to make symlinks (Developer Mode, or an elevated PowerShell).

Starship reads `.config/starship.toml`. `.config/starship-config.toml` is a second copy and is not loaded.

Then edit the two hardcoded paths:

- `profile powershell`: both `C:/Users/fabri/.config/fastfetch/...` lines
- `.config/fastfetch/config.jsonc`: `logo.source`

Point them at `$env:USERPROFILE\.config\fastfetch`.

Start YASB from the Start menu. Its config starts GlazeWM. To launch them at login, put a shortcut to `yasb.exe` in `shell:startup`.

## Already installed

```powershell
cd $env:USERPROFILE\Developer\my-dotfiles
git pull
```

Symlinks pick up the pull. Reload GlazeWM with Alt+Shift+R, and restart YASB if the bar does not reload on its own.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| Alt+Enter | Windows Terminal |
| Alt+H/J/K/L | Focus window |
| Alt+Shift+H/J/K/L | Move window |
| Alt+V | Toggle tiling direction |
| Alt+T | Tile |
| Alt+Shift+Space | Float |
| Alt+F | Fullscreen |
| Alt+Shift+Q | Close window |
| Alt+1 … | Switch workspace |
| Alt+Shift+R | Reload GlazeWM |
| Alt+Shift+E | Exit GlazeWM |
