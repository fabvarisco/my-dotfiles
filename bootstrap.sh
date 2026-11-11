#!/usr/bin/env bash
# ============================================================================
#  bootstrap.sh — set up a fresh Ubuntu WSL as a dev environment.
#  Run INSIDE WSL as your normal user (not root). The clone folder can have
#  any name; the script uses its own directory:
#
#     git clone -b wsl/ubuntu-nix https://github.com/fabvarisco/my-dotfiles
#     cd my-dotfiles && ./bootstrap.sh
#
#  Safe to run again (idempotent).
#  Flags:  -y / --yes   accept the defaults, no questions
# ============================================================================
set -euo pipefail

ASSUME_YES=0
for arg in "$@"; do
  case "$arg" in
    -y | --yes) ASSUME_YES=1 ;;
    -h | --help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "unknown flag: $arg" >&2
      exit 2
      ;;
  esac
done

c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_red=$'\033[31m'; c_reset=$'\033[0m'
step() { printf '\n%s==>%s %s\n' "$c_green" "$c_reset" "$*"; }
warn() { printf '%s[!]%s %s\n' "$c_yellow" "$c_reset" "$*"; }
die() { printf '%s[x]%s %s\n' "$c_red" "$c_reset" "$*" >&2; exit 1; }
confirm() { # confirm "question" -> 0 = yes (default yes)
  [ "$ASSUME_YES" = 1 ] && return 0
  local ans
  read -r -p "$1 [Y/n] " ans || true
  [[ -z "$ans" || "$ans" =~ ^[Yy] ]]
}

# Every nix invocation in this script opts into flakes, even when the
# installed Nix (upstream or Determinate) has not enabled them yet.
run_nix() {
  command nix --extra-experimental-features 'nix-command flakes' "$@"
}

nix_is_installed() {
  [ -x /nix/var/nix/profiles/default/bin/nix ] || [ -x "$HOME/.nix-profile/bin/nix" ] || command -v nix >/dev/null 2>&1
}

load_nix_profile() {
  if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  elif [ -e /etc/profile.d/nix.sh ]; then
    # shellcheck disable=SC1091
    . /etc/profile.d/nix.sh
  else
    die "Nix looks installed, but its profile script was not found."
  fi
}

# Determinate reads extra settings from nix.custom.conf (included by nix.conf).
# Upstream Nix reads /etc/nix/nix.conf only.
nix_system_conf() {
  if [ -f /etc/nix/nix.custom.conf ]; then
    printf '%s\n' /etc/nix/nix.custom.conf
    return
  fi
  if [ -f /etc/nix/nix.conf ] && grep -qs 'nix.custom.conf' /etc/nix/nix.conf; then
    printf '%s\n' /etc/nix/nix.custom.conf
    return
  fi
  printf '%s\n' /etc/nix/nix.conf
}

nix_features_text() {
  command nix config show experimental-features 2>/dev/null || true
}

nix_features_ok() {
  local features
  features="$(nix_features_text)"
  printf '%s\n' "$features" | grep -qw nix-command && printf '%s\n' "$features" | grep -qw flakes
}

# Rewrite or append one experimental-features line. $2 is "sudo" or "user".
ensure_features_file() {
  local file="$1" mode="$2"
  local dir tmp
  dir="$(dirname "$file")"
  if [ "$mode" = sudo ]; then
    sudo mkdir -p "$dir"
    sudo touch "$file"
    tmp="$(mktemp)"
    sudo awk '
      BEGIN { found = 0 }
      /^[[:space:]]*experimental-features[[:space:]]*=/ && !found {
        found = 1
        line = $0
        sub(/^[^=]*=[[:space:]]*/, "", line)
        n = split(line, toks, /[[:space:]]+/)
        has_cmd = 0
        has_flakes = 0
        out = ""
        for (i = 1; i <= n; i++) {
          if (toks[i] == "") continue
          if (toks[i] == "nix-command") has_cmd = 1
          if (toks[i] == "flakes") has_flakes = 1
          out = out (out == "" ? "" : " ") toks[i]
        }
        if (!has_cmd) out = out (out == "" ? "" : " ") "nix-command"
        if (!has_flakes) out = out (out == "" ? "" : " ") "flakes"
        print "experimental-features = " out
        next
      }
      { print }
      END {
        if (!found) print "experimental-features = nix-command flakes"
      }
    ' "$file" | tee "$tmp" >/dev/null
    sudo cp "$tmp" "$file"
    rm -f "$tmp"
  else
    mkdir -p "$dir"
    touch "$file"
    tmp="$(mktemp)"
    awk '
      BEGIN { found = 0 }
      /^[[:space:]]*experimental-features[[:space:]]*=/ && !found {
        found = 1
        line = $0
        sub(/^[^=]*=[[:space:]]*/, "", line)
        n = split(line, toks, /[[:space:]]+/)
        has_cmd = 0
        has_flakes = 0
        out = ""
        for (i = 1; i <= n; i++) {
          if (toks[i] == "") continue
          if (toks[i] == "nix-command") has_cmd = 1
          if (toks[i] == "flakes") has_flakes = 1
          out = out (out == "" ? "" : " ") toks[i]
        }
        if (!has_cmd) out = out (out == "" ? "" : " ") "nix-command"
        if (!has_flakes) out = out (out == "" ? "" : " ") "flakes"
        print "experimental-features = " out
        next
      }
      { print }
      END {
        if (!found) print "experimental-features = nix-command flakes"
      }
    ' "$file" >"$tmp"
    mv "$tmp" "$file"
  fi
}

trusted_user_present() {
  local file="$1"
  [ -f "$file" ] || return 1
  sudo grep -E '^[[:space:]]*trusted-users[[:space:]]*=' "$file" 2>/dev/null \
    | grep -Eq "(^|[[:space:]])${USER}([[:space:]]|$)"
}

ensure_trusted_user() {
  local file="$1"
  sudo mkdir -p "$(dirname "$file")"
  sudo touch "$file"
  if trusted_user_present "$file"; then
    return 0
  fi
  if sudo grep -qE '^[[:space:]]*trusted-users[[:space:]]*=' "$file"; then
    local tmp
    tmp="$(mktemp)"
    sudo awk -v user="$USER" '
      /^[[:space:]]*trusted-users[[:space:]]*=/ && !done {
        done = 1
        print $0 " " user
        next
      }
      { print }
    ' "$file" | tee "$tmp" >/dev/null
    sudo cp "$tmp" "$file"
    rm -f "$tmp"
  else
    printf 'trusted-users = root %s\n' "$USER" | sudo tee -a "$file" >/dev/null
  fi
  NIX_CONF_CHANGED=1
}

restart_nix_daemon_if_needed() {
  if [ "$(ps -p 1 -o comm= 2>/dev/null || true)" != "systemd" ]; then
    return 0
  fi
  if ! command -v systemctl >/dev/null 2>&1; then
    return 0
  fi
  if systemctl cat nix-daemon.service >/dev/null 2>&1; then
    sudo systemctl restart nix-daemon.service \
      || warn "Could not restart nix-daemon. If builds fail, run: sudo systemctl restart nix-daemon"
  fi
}

# Stop here when the file is sourced so tests can call the helpers above.
if [ "${BOOTSTRAP_LIB_ONLY:-}" = 1 ]; then
  if [ "${BASH_SOURCE[0]}" != "$0" ]; then
    return 0
  fi
  exit 0
fi

# ----------------------------------------------------------------------------
# 0. Sanity
# ----------------------------------------------------------------------------
[ "$(id -u)" -ne 0 ] || die "Do not run as root. Run as your user (sudo is called when it is needed)."
if ! grep -qi microsoft /proc/version 2>/dev/null; then
  warn "This does not look like WSL. Continuing anyway."
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# A repo under /mnt/c is SLOW and hits permission problems -> copy it to ~/
# under the same folder name (does not assume hitsu-wsl-setup or my-dotfiles).
case "$SCRIPT_DIR" in
  /mnt/*)
    repo_name="$(basename "$SCRIPT_DIR")"
    dest="$HOME/$repo_name"
    step "The repo is at $SCRIPT_DIR (Windows disk). Copying it to $dest"
    if [ -e "$dest" ]; then
      die "$dest already exists. Run bootstrap from there: cd \"$dest\" && ./bootstrap.sh"
    fi
    cp -a "$SCRIPT_DIR" "$dest"
    exec "$dest/bootstrap.sh" "$@"
    ;;
esac

cd "$SCRIPT_DIR"

mkdir -p "$HOME/.local/share/wsl-nix"
printf '%s\n' "$SCRIPT_DIR" > "$HOME/.local/share/wsl-nix/flake-dir"

# ----------------------------------------------------------------------------
# 1. Minimum apt packages (everything else comes from Nix)
# ----------------------------------------------------------------------------
step "Installing the minimum apt dependencies"
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  ca-certificates curl git xz-utils zsh build-essential locales

# UTF-8 locale (keeps starship/herdr from showing broken characters)
if ! locale -a 2>/dev/null | grep -qi '^en_US\.utf-\?8$'; then
  sudo locale-gen en_US.UTF-8
fi

# ----------------------------------------------------------------------------
# 2. systemd (the Nix daemon depends on it). Ubuntu on WSL already ships with it on.
# ----------------------------------------------------------------------------
if [ "$(ps -p 1 -o comm= 2>/dev/null)" != "systemd" ]; then
  warn "systemd is not running as PID 1."
  if ! grep -qs '^systemd *= *true' /etc/wsl.conf; then
    step "Enabling systemd in /etc/wsl.conf"
    printf '\n[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf >/dev/null
  fi
  die "Close WSL, run this in PowerShell:  wsl --shutdown   then run this script again."
fi

# ----------------------------------------------------------------------------
# 3. Nix (Determinate Systems installer: flakes on, clean uninstall)
#    A Nix that is already installed (upstream or Determinate) is kept.
#    flakes and nix-command are turned on in its config, and every nix
#    command below also passes them on the command line.
# ----------------------------------------------------------------------------
if nix_is_installed; then
  step "Nix is already installed — skipping the installer"
else
  step "Installing Nix (Determinate Systems)"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi

load_nix_profile

NIX_CONF="$(nix_system_conf)"
NIX_CONF_CHANGED=0
if ! nix_features_ok; then
  step "Enabling nix-command and flakes in $NIX_CONF"
  ensure_features_file "$NIX_CONF" sudo
  NIX_CONF_CHANGED=1
  if ! nix_features_ok; then
    # A user nix.conf overrides /etc. Patch that file too.
    user_nix_conf="${XDG_CONFIG_HOME:-$HOME/.config}/nix/nix.conf"
    step "Enabling nix-command and flakes in $user_nix_conf"
    ensure_features_file "$user_nix_conf" user
  fi
fi

# trusted-users lets devenv use its binary cache. Without it, a lot of
# things build from source. Determinate: nix.custom.conf. Upstream: nix.conf.
if ! trusted_user_present "$NIX_CONF"; then
  step "Adding $USER to trusted-users ($NIX_CONF)"
  ensure_trusted_user "$NIX_CONF"
fi

if [ "$NIX_CONF_CHANGED" = 1 ]; then
  restart_nix_daemon_if_needed
fi

# Inherited by home-manager's own nix calls during this run.
export NIX_CONFIG="${NIX_CONFIG:+$NIX_CONFIG$'\n'}experimental-features = nix-command flakes"

run_nix --version

# ----------------------------------------------------------------------------
# 4. Check the user in user.nix
# ----------------------------------------------------------------------------
FLAKE_USER="$(sed -n 's/^[[:space:]]*username[[:space:]]*=[[:space:]]*"\([^"]*\)".*/\1/p' user.nix | head -n1)"
if [ "$FLAKE_USER" != "$USER" ]; then
  warn "user.nix has username = \"$FLAKE_USER\", but you are \"$USER\"."
  if confirm "Change user.nix to \"$USER\" automatically?"; then
    sed -i "s/^\([[:space:]]*username[[:space:]]*=[[:space:]]*\)\"[^\"]*\"/\1\"$USER\"/" user.nix
  else
    die "Edit user.nix and run this script again."
  fi
fi
if grep -q 'you@example.com' user.nix; then
  warn "user.nix still has the example email. Edit it later and run: hms"
fi

# Flakes only see files tracked by git
if [ ! -d .git ]; then
  git init -q -b main
fi
git add -A

# ----------------------------------------------------------------------------
# 5. home-manager switch (installs EVERYTHING: zsh, nvim, herdr, AIs, node, python...)
# ----------------------------------------------------------------------------
step "Applying the home-manager configuration (the first run takes a while)"
run_nix run .#home-manager -- switch --flake ".#$USER" -b hm-backup

# ----------------------------------------------------------------------------
# 6. zsh as the default shell (uses apt's zsh: /usr/bin/zsh; the config comes from home-manager)
# ----------------------------------------------------------------------------
ZSH_BIN="$(command -v zsh || true)"
[ -x /usr/bin/zsh ] && ZSH_BIN=/usr/bin/zsh
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [ -n "$ZSH_BIN" ] && [ "$CURRENT_SHELL" != "$ZSH_BIN" ]; then
  step "Changing your default shell to $ZSH_BIN"
  grep -qx "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
  sudo chsh -s "$ZSH_BIN" "$USER"
fi

# ----------------------------------------------------------------------------
# 7. Installs outside Nix: NONE required.
#    herdr, claude-code, codex, opencode, devenv, node, python, uv -> nixpkgs.
#    (If one ever leaves nixpkgs, the official installers are in the README.)
# ----------------------------------------------------------------------------

# ----------------------------------------------------------------------------
# 8. Next steps
# ----------------------------------------------------------------------------
cat <<MSG

${c_green}✔ Done!${c_reset}  Close and reopen the terminal (or run: exec zsh -l)

Next steps:
  1. Check ${SCRIPT_DIR}/user.nix (git user/name/email) and run:  hms
  2. GitHub:        gh auth login
  3. Claude Code:   claude          (login opens in the Windows browser)
  4. Codex:         codex login
  5. opencode:      opencode auth login
  6. herdr:         herdr           (ctrl+b q detaches, 'herdr' reattaches)
  7. New project:   cp -r ${SCRIPT_DIR}/templates/node ~/code/my-app   (includes .envrc)
                    cd ~/code/my-app && direnv allow
  8. Zed (Windows): Ctrl+Shift+P -> "projects: open wsl" -> choose Ubuntu-26.04

Update everything:  hmu        Roll back:  home-manager generations  (see the README)
MSG
