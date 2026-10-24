# Windows GlazeWM + YASB

Dotfiles for a tiling desktop on Windows 11: GlazeWM, YASB, Starship, and Fastfetch. Window borders from GlazeWM need Windows 11.

`.config/fastfetch/config.jsonc` still sets `logo.source` to `C:\Users\fabri\.config\fastfetch\ascii.txt`. The PowerShell profile ignores that and picks a random file from `ascii-arts`. Change `logo.source` if you run Fastfetch without the profile.

## Install the programs

```powershell
winget install --id glzr-io.GlazeWM -e
winget install --id amnweb.YASB -e
winget install --id Starship.Starship -e
winget install --id fastfetch-cli.Fastfetch -e
winget install --id Microsoft.PowerShell -e
```

The bar and the prompt use JetBrainsMono Nerd Font (`JetBrainsMono NFP`). Install that font and restart the terminal. YASB icons also use Segoe MDL2 Assets, which ships with Windows.

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
New-Item -ItemType SymbolicLink -Force -Path $PROFILE -Target "$PWD\.config\powerShellProfile.ps1"
```

Creating those links needs a terminal allowed to make symlinks (Developer Mode, or an elevated PowerShell).

Starship reads `.config/starship.toml`. The PowerShell profile loads Starship and Fastfetch from `$HOME\.config`.

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
