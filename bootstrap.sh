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
CONFIGURE_ONLY=0
RECONFIGURE=0
FLAG_USER="${WSL_NIX_USER:-}"
FLAG_NAME="${WSL_NIX_NAME:-}"
FLAG_EMAIL="${WSL_NIX_EMAIL:-}"
FLAG_EDITOR="${WSL_NIX_EDITOR:-}"
FLAG_EDITOR_CMD="${WSL_NIX_EDITOR_CMD:-}"
FLAG_BRANCH="${WSL_NIX_GIT_BRANCH:-}"
FLAG_AI="${WSL_NIX_AI:-}"
FLAG_HERDR="${WSL_NIX_HERDR:-}"
FLAG_FASTFETCH="${WSL_NIX_FASTFETCH:-}"
FLAG_ZSH="${WSL_NIX_ZSH:-}"
SET_USER=0
SET_NAME=0
SET_EMAIL=0
SET_EDITOR=0
SET_EDITOR_CMD=0
SET_BRANCH=0
SET_AI=0
SET_HERDR=0
SET_FASTFETCH=0
SET_ZSH=0
[ -n "$FLAG_USER" ] && SET_USER=1
[ -n "$FLAG_NAME" ] && SET_NAME=1
[ -n "$FLAG_EMAIL" ] && SET_EMAIL=1
[ -n "$FLAG_EDITOR" ] && SET_EDITOR=1
[ -n "$FLAG_EDITOR_CMD" ] && SET_EDITOR_CMD=1
[ -n "$FLAG_BRANCH" ] && SET_BRANCH=1
[ -n "$FLAG_AI" ] && SET_AI=1
[ -n "$FLAG_HERDR" ] && SET_HERDR=1
[ -n "$FLAG_FASTFETCH" ] && SET_FASTFETCH=1
[ -n "$FLAG_ZSH" ] && SET_ZSH=1

print_help() {
  cat <<'EOF'
bootstrap.sh — set up this Ubuntu WSL clone.

  ./bootstrap.sh [options]

Options:
  -y, --yes            Use detected/saved defaults and do not ask
  --configure-only     Write the per-user file and exit (no apt, Nix, or switch)
  --reconfigure        Walk through the prompts again (saved answers are the defaults)
  --user NAME          Linux username (default: $USER or WSL_NIX_USER)
  --name NAME          Git full name (WSL_NIX_NAME)
  --email ADDR         Git email (WSL_NIX_EMAIL)
  --editor CHOICE      nvim, zed, or other (WSL_NIX_EDITOR)
  --editor-cmd CMD     Command used when --editor other (WSL_NIX_EDITOR_CMD)
  --git-branch NAME    git init.defaultBranch (WSL_NIX_GIT_BRANCH)
  --ai LIST            Comma-separated claude-code,codex,opencode, or all, or none (WSL_NIX_AI)
  --herdr / --no-herdr Install herdr and its plugins (WSL_NIX_HERDR=yes|no)
  --fastfetch / --no-fastfetch
                       Run fastfetch when zsh starts (WSL_NIX_FASTFETCH=yes|no)
  --zsh / --no-zsh     Make zsh the login shell (WSL_NIX_ZSH=yes|no)
  -h, --help           Show this help

Answers are saved to ~/.config/wsl-nix/user.nix and copied to ./user.nix.
./user.nix stays tracked so Nix can read it, and is marked skip-worktree so
your answers are not committed. See user.nix.example and the README.
EOF
}

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
confirm_no() { # confirm_no "question" -> 0 = yes (default no)
  [ "$ASSUME_YES" = 1 ] && return 1
  local ans
  read -r -p "$1 [y/N] " ans || true
  [[ "$ans" =~ ^[Yy] ]]
}

# Nyanca's mark. Cyan only on a real terminal, and never when NO_COLOR is set.
print_banner() {
  local cyan="" reset=""
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    cyan=$'\033[96m'
    reset=$'\033[0m'
  fi
  printf '%s' "$cyan"
  cat <<'EOF'
    /\_/\
   ( o.o )
  <(  ^  )>
   /| V |\
  / |   | \
 (  |   |  )
  \_|___|_/
   /_/ \_\
  wsl/ubuntu-nix bootstrap  -  crafted by Nyanca  nya~
EOF
  printf '%s\n' "$reset"
}

if [ "${BOOTSTRAP_LIB_ONLY:-}" != 1 ]; then
  print_banner
fi

while [ $# -gt 0 ]; do
  case "$1" in
    -y | --yes) ASSUME_YES=1; shift ;;
    --configure-only) CONFIGURE_ONLY=1; shift ;;
    --reconfigure) RECONFIGURE=1; shift ;;
    --user)
      [ $# -ge 2 ] || die "--user needs a value"
      FLAG_USER="$2"; SET_USER=1; shift 2 ;;
    --name)
      [ $# -ge 2 ] || die "--name needs a value"
      FLAG_NAME="$2"; SET_NAME=1; shift 2 ;;
    --email)
      [ $# -ge 2 ] || die "--email needs a value"
      FLAG_EMAIL="$2"; SET_EMAIL=1; shift 2 ;;
    --editor)
      [ $# -ge 2 ] || die "--editor needs a value"
      FLAG_EDITOR="$2"; SET_EDITOR=1; shift 2 ;;
    --editor-cmd)
      [ $# -ge 2 ] || die "--editor-cmd needs a value"
      FLAG_EDITOR_CMD="$2"; SET_EDITOR_CMD=1; shift 2 ;;
    --git-branch)
      [ $# -ge 2 ] || die "--git-branch needs a value"
      FLAG_BRANCH="$2"; SET_BRANCH=1; shift 2 ;;
    --ai)
      [ $# -ge 2 ] || die "--ai needs a value"
      FLAG_AI="$2"; SET_AI=1; shift 2 ;;
    --herdr) FLAG_HERDR=yes; SET_HERDR=1; shift ;;
    --no-herdr) FLAG_HERDR=no; SET_HERDR=1; shift ;;
    --fastfetch) FLAG_FASTFETCH=yes; SET_FASTFETCH=1; shift ;;
    --no-fastfetch) FLAG_FASTFETCH=no; SET_FASTFETCH=1; shift ;;
    --zsh) FLAG_ZSH=yes; SET_ZSH=1; shift ;;
    --no-zsh) FLAG_ZSH=no; SET_ZSH=1; shift ;;
    -h | --help) print_help; exit 0 ;;
    *)
      die "unknown flag: $1 (try --help)"
      ;;
  esac
done

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

# --- per-person config -------------------------------------------------------
ANSWERS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/wsl-nix"
ANSWERS_FILE="$ANSWERS_DIR/user.nix"

nix_q() {
  # Escape a string for a Nix double-quoted literal.
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

field_string() {
  local key="$1" file="$2"
  sed -n "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" "$file" | head -n1
}

field_bool() {
  local key="$1" file="$2" raw
  raw="$(sed -n "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*\\(true\\|false\\).*/\\1/p" "$file" | head -n1)"
  if [ "$raw" = true ]; then
    printf 'yes\n'
  elif [ "$raw" = false ]; then
    printf 'no\n'
  fi
}

field_ai() {
  local file="$1"
  awk '
    /^[[:space:]]*aiClis[[:space:]]*=/ { grab=1 }
    grab { print }
    grab && /\]/ { exit }
  ' "$file" | sed -n 's/.*"\([^"]*\)".*/\1/p' | paste -sd, -
}

detect_full_name() {
  local name=""
  name="$(git config --global user.name 2>/dev/null || true)"
  if [ -z "$name" ]; then
    name="$(getent passwd "$USER" 2>/dev/null | cut -d: -f5 | cut -d, -f1)"
  fi
  printf '%s\n' "$name"
}

detect_email() {
  git config --global user.email 2>/dev/null || true
}

detect_system() {
  case "$(uname -m)" in
    aarch64 | arm64) printf 'aarch64-linux\n' ;;
    *) printf 'x86_64-linux\n' ;;
  esac
}

load_saved_answers() {
  HAVE_SAVED=0
  SAVED_USER=""
  SAVED_NAME=""
  SAVED_EMAIL=""
  SAVED_EDITOR=""
  SAVED_EDITOR_CMD=""
  SAVED_BRANCH=""
  SAVED_AI=""
  SAVED_HERDR=""
  SAVED_FASTFETCH=""
  SAVED_ZSH=""
  SAVED_SYSTEM=""
  local src=""
  if [ -f "$ANSWERS_FILE" ]; then
    src="$ANSWERS_FILE"
  elif [ -f "$SCRIPT_DIR/user.nix" ]; then
    src="$SCRIPT_DIR/user.nix"
  fi
  [ -n "$src" ] || return 0
  if grep -q 'you@example.com' "$src"; then
    return 0
  fi
  HAVE_SAVED=1
  SAVED_USER="$(field_string username "$src")"
  SAVED_NAME="$(field_string fullName "$src")"
  SAVED_EMAIL="$(field_string email "$src")"
  SAVED_EDITOR="$(field_string editor "$src")"
  SAVED_EDITOR_CMD="$(field_string editorCommand "$src")"
  SAVED_BRANCH="$(field_string gitDefaultBranch "$src")"
  SAVED_AI="$(field_ai "$src")"
  SAVED_HERDR="$(field_bool herdr "$src")"
  SAVED_FASTFETCH="$(field_bool fastfetchOnStart "$src")"
  SAVED_ZSH="$(field_bool zshAsLoginShell "$src")"
  SAVED_SYSTEM="$(field_string system "$src")"
}

prompt_value() {
  # prompt_value VAR "Question" default
  local __var="$1" question="$2" def="$3" ans
  if [ "$ASSUME_YES" = 1 ]; then
    printf -v "$__var" '%s' "$def"
    return
  fi
  read -r -p "$question [$def]: " ans || true
  if [ -z "$ans" ]; then
    printf -v "$__var" '%s' "$def"
  else
    printf -v "$__var" '%s' "$ans"
  fi
}

normalize_ai() {
  local raw="$1" item out=""
  raw="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | tr -d ' ')"
  if [ -z "$raw" ] || [ "$raw" = all ]; then
    printf '%s\n' "claude-code,codex,opencode"
    return
  fi
  if [ "$raw" = none ]; then
    printf '\n'
    return
  fi
  IFS=',' read -r -a _ai_items <<< "$raw"
  for item in "${_ai_items[@]}"; do
    case "$item" in
      claude-code | codex | opencode)
        case ",$out," in
          *",$item,"*) ;;
          *) out="${out:+$out,}$item" ;;
        esac
        ;;
      "") ;;
      *) die "Unknown AI CLI: $item (use claude-code, codex, opencode, all, or none)" ;;
    esac
  done
  printf '%s\n' "$out"
}

yn_to_bool() {
  case "$1" in
    yes | y | true | 1) printf 'true\n' ;;
    *) printf 'false\n' ;;
  esac
}

ai_to_nix() {
  local raw="$1" item line="["
  if [ -z "$raw" ]; then
    printf '[\n  ]\n'
    return
  fi
  IFS=',' read -r -a _ai_items <<< "$raw"
  for item in "${_ai_items[@]}"; do
    line="${line}
    \"$(nix_q "$item")\""
  done
  printf '%s\n  ]\n' "$line"
}

write_user_nix() {
  local dest="$1" ai_block
  ai_block="$(ai_to_nix "$CFG_AI")"
  mkdir -p "$(dirname "$dest")"
  cat >"$dest" <<EOF
# Generated by bootstrap.sh. Re-run ./bootstrap.sh to change these answers.
# The copy in the repo is marked skip-worktree so it is not committed.
{
  username = "$(nix_q "$CFG_USER")";
  fullName = "$(nix_q "$CFG_NAME")";
  email = "$(nix_q "$CFG_EMAIL")";
  system = "$(nix_q "$CFG_SYSTEM")";
  editor = "$(nix_q "$CFG_EDITOR")"; # nvim, zed, or other
  editorCommand = "$(nix_q "$CFG_EDITOR_CMD")"; # used when editor = "other"
  gitDefaultBranch = "$(nix_q "$CFG_BRANCH")";
  aiClis = ${ai_block};
  herdr = $(yn_to_bool "$CFG_HERDR");
  fastfetchOnStart = $(yn_to_bool "$CFG_FASTFETCH");
  zshAsLoginShell = $(yn_to_bool "$CFG_ZSH");
}
EOF
}

collect_config() {
  local detected_name detected_email def_user def_name def_email def_editor def_cmd def_branch def_ai def_herdr def_ff def_zsh
  load_saved_answers
  detected_name="$(detect_full_name)"
  detected_email="$(detect_email)"
  def_user="${SAVED_USER:-$USER}"
  def_name="${SAVED_NAME:-${detected_name:-Your Name}}"
  def_email="${SAVED_EMAIL:-${detected_email:-you@example.com}}"
  def_editor="${SAVED_EDITOR:-nvim}"
  def_cmd="${SAVED_EDITOR_CMD:-nvim}"
  def_branch="${SAVED_BRANCH:-main}"
  if [ "$HAVE_SAVED" = 1 ]; then
    def_ai="${SAVED_AI:-none}"
  else
    def_ai="claude-code,codex,opencode"
  fi
  def_herdr="${SAVED_HERDR:-yes}"
  def_ff="${SAVED_FASTFETCH:-yes}"
  def_zsh="${SAVED_ZSH:-yes}"
  CFG_SYSTEM="${SAVED_SYSTEM:-$(detect_system)}"

  if [ "$HAVE_SAVED" = 1 ] && [ "$RECONFIGURE" = 0 ] && [ "$ASSUME_YES" = 0 ]; then
    echo "Saved answers: $ANSWERS_FILE"
    if confirm_no "Walk through the prompts again?"; then
      RECONFIGURE=1
    fi
  fi

  local ask=0
  if [ "$HAVE_SAVED" = 0 ] || [ "$RECONFIGURE" = 1 ]; then
    ask=1
  fi

  if [ "$SET_USER" = 1 ]; then CFG_USER="$FLAG_USER"
  elif [ "$ask" = 1 ]; then prompt_value CFG_USER "Linux username" "$def_user"
  else CFG_USER="$def_user"; fi

  if [ "$SET_NAME" = 1 ]; then CFG_NAME="$FLAG_NAME"
  elif [ "$ask" = 1 ]; then prompt_value CFG_NAME "Full name for git" "$def_name"
  else CFG_NAME="$def_name"; fi

  if [ "$SET_EMAIL" = 1 ]; then CFG_EMAIL="$FLAG_EMAIL"
  elif [ "$ask" = 1 ]; then prompt_value CFG_EMAIL "Git email" "$def_email"
  else CFG_EMAIL="$def_email"; fi

  if [ "$SET_EDITOR" = 1 ]; then CFG_EDITOR="$FLAG_EDITOR"
  elif [ "$ask" = 1 ]; then prompt_value CFG_EDITOR "Default editor (nvim, zed, or other)" "$def_editor"
  else CFG_EDITOR="$def_editor"; fi
  case "$CFG_EDITOR" in
    nvim | zed | other) ;;
    *) die "Editor must be nvim, zed, or other (got: $CFG_EDITOR)" ;;
  esac

  if [ "$CFG_EDITOR" = other ]; then
    if [ "$SET_EDITOR_CMD" = 1 ]; then CFG_EDITOR_CMD="$FLAG_EDITOR_CMD"
    elif [ "$ask" = 1 ]; then prompt_value CFG_EDITOR_CMD "Editor command" "$def_cmd"
    else CFG_EDITOR_CMD="$def_cmd"; fi
  else
    CFG_EDITOR_CMD="${FLAG_EDITOR_CMD:-$def_cmd}"
  fi

  if [ "$SET_BRANCH" = 1 ]; then CFG_BRANCH="$FLAG_BRANCH"
  elif [ "$ask" = 1 ]; then prompt_value CFG_BRANCH "Git default branch" "$def_branch"
  else CFG_BRANCH="$def_branch"; fi

  if [ "$SET_AI" = 1 ]; then CFG_AI="$(normalize_ai "$FLAG_AI")"
  elif [ "$ask" = 1 ]; then
    echo "AI CLIs: comma-separated claude-code,codex,opencode, or all, or none."
    prompt_value CFG_AI "AI CLIs to install" "${def_ai:-all}"
    CFG_AI="$(normalize_ai "$CFG_AI")"
  else CFG_AI="$(normalize_ai "${def_ai:-all}")"; fi

  if [ "$SET_HERDR" = 1 ]; then CFG_HERDR="$FLAG_HERDR"
  elif [ "$ask" = 1 ]; then
    if [ "$def_herdr" = no ]; then
      if confirm_no "Install herdr and its plugins?"; then CFG_HERDR=yes; else CFG_HERDR=no; fi
    else
      if confirm "Install herdr and its plugins?"; then CFG_HERDR=yes; else CFG_HERDR=no; fi
    fi
  else CFG_HERDR="$def_herdr"; fi

  if [ "$SET_FASTFETCH" = 1 ]; then CFG_FASTFETCH="$FLAG_FASTFETCH"
  elif [ "$ask" = 1 ]; then
    if [ "$def_ff" = no ]; then
      if confirm_no "Run fastfetch when the shell starts?"; then CFG_FASTFETCH=yes; else CFG_FASTFETCH=no; fi
    else
      if confirm "Run fastfetch when the shell starts?"; then CFG_FASTFETCH=yes; else CFG_FASTFETCH=no; fi
    fi
  else CFG_FASTFETCH="$def_ff"; fi

  if [ "$SET_ZSH" = 1 ]; then CFG_ZSH="$FLAG_ZSH"
  elif [ "$ask" = 1 ]; then
    if [ "$def_zsh" = no ]; then
      if confirm_no "Make zsh your login shell?"; then CFG_ZSH=yes; else CFG_ZSH=no; fi
    else
      if confirm "Make zsh your login shell?"; then CFG_ZSH=yes; else CFG_ZSH=no; fi
    fi
  else CFG_ZSH="$def_zsh"; fi

  case "$CFG_HERDR" in
    yes | no) ;;
    *) die "herdr must be yes or no" ;;
  esac
  case "$CFG_FASTFETCH" in
    yes | no) ;;
    *) die "fastfetch must be yes or no" ;;
  esac
  case "$CFG_ZSH" in
    yes | no) ;;
    *) die "zsh must be yes or no" ;;
  esac

  if [ "$CFG_USER" != "$USER" ]; then
    warn "username is \"$CFG_USER\" but whoami is \"$USER\". home-manager will refuse to switch unless they match."
  fi

  echo
  echo "Configuration:"
  echo "  username:            $CFG_USER"
  echo "  full name:           $CFG_NAME"
  echo "  email:               $CFG_EMAIL"
  echo "  system:              $CFG_SYSTEM"
  echo "  editor:              $CFG_EDITOR${CFG_EDITOR:+${CFG_EDITOR_CMD:+ ($CFG_EDITOR_CMD)}}"
  echo "  git default branch:  $CFG_BRANCH"
  echo "  AI CLIs:             ${CFG_AI:-none}"
  echo "  herdr + plugins:     $CFG_HERDR"
  echo "  fastfetch on start:  $CFG_FASTFETCH"
  echo "  zsh as login shell:  $CFG_ZSH"
  echo
  echo "Windows: powershell -ExecutionPolicy Bypass -File .\\windows\\setup.ps1"
  echo "         It asks for WSL memory (default half of RAM), CPUs (default all cores), and swap (default 4GB)."
  echo
  confirm "Apply this configuration?" || die "Cancelled."
}

save_user_nix() {
  write_user_nix "$ANSWERS_FILE"
  write_user_nix "$SCRIPT_DIR/user.nix"
  if [ -d "$SCRIPT_DIR/.git" ]; then
    git -C "$SCRIPT_DIR" update-index --skip-worktree user.nix 2>/dev/null || true
  fi
  step "Wrote $ANSWERS_FILE and marked $SCRIPT_DIR/user.nix skip-worktree"
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
# Per-person answers. Written before apt/Nix so --configure-only can stop here.
# ./user.nix is tracked (Nix cannot see a gitignored file) and skip-worktree
# so the committed copy stays the example in user.nix.example.
# ----------------------------------------------------------------------------
collect_config
save_user_nix
if [ "$CONFIGURE_ONLY" = 1 ]; then
  echo "Configuration saved. Re-run without --configure-only to install."
  exit 0
fi

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
# 4. The generated user.nix is already written. Nix only sees tracked files,
#    so ./user.nix is that file (skip-worktree), not a gitignored copy.
# ----------------------------------------------------------------------------
if [ "$CFG_USER" != "$USER" ]; then
  die "Refusing to switch: user.nix username is \"$CFG_USER\" but this login is \"$USER\"."
fi

# Flakes only see files tracked by git. user.nix is tracked so this eval
# can read it, and skip-worktree keeps the generated answers out of the commit.
if [ ! -d .git ]; then
  git init -q -b main
  git add -A
  git update-index --skip-worktree user.nix 2>/dev/null || true
else
  git update-index --skip-worktree user.nix 2>/dev/null || true
  git add -A
fi

# ----------------------------------------------------------------------------
# 5. home-manager switch (installs EVERYTHING: zsh, nvim, herdr, AIs, node, python...)
# ----------------------------------------------------------------------------
step "Applying the home-manager configuration (the first run takes a while)"
export WSL_NIX_USER_FILE="$ANSWERS_FILE"
run_nix run .#home-manager -- switch --flake ".#$CFG_USER" -b hm-backup

# ----------------------------------------------------------------------------
# 6. zsh as the default shell (uses apt's zsh: /usr/bin/zsh; the config comes from home-manager)
# ----------------------------------------------------------------------------
if [ "$CFG_ZSH" = yes ]; then
  ZSH_BIN="$(command -v zsh || true)"
  [ -x /usr/bin/zsh ] && ZSH_BIN=/usr/bin/zsh
  CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
  if [ -n "$ZSH_BIN" ] && [ "$CURRENT_SHELL" != "$ZSH_BIN" ]; then
    step "Changing your default shell to $ZSH_BIN"
    grep -qx "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
    sudo chsh -s "$ZSH_BIN" "$USER"
  fi
else
  step "Leaving the login shell unchanged"
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

${c_green}Done.${c_reset}  Close and reopen the terminal (or run: exec zsh -l)

Next steps:
  1. Change answers any time with:  ./bootstrap.sh --reconfigure
  2. GitHub:        gh auth login
$(if [ -n "$CFG_AI" ]; then cat <<AIS

  AI CLIs selected: ${CFG_AI}
    claude-code -> claude     (login opens in the Windows browser)
    codex       -> codex login
    opencode    -> opencode auth login
AIS
fi)
$(if [ "$CFG_HERDR" = yes ]; then echo "  herdr:        herdr    (ctrl+b q detaches, herdr again reattaches)"; fi)
  New project:  cp -r ${SCRIPT_DIR}/templates/node ~/code/my-app && cd ~/code/my-app && direnv allow
  Zed (Windows): Ctrl+Shift+P -> "projects: open wsl" -> choose Ubuntu-26.04
  Windows VM size: powershell -ExecutionPolicy Bypass -File .\\windows\\setup.ps1
    It asks for memory (default half of RAM), CPUs (default all cores), and swap (default 4GB).

Update everything:  hmu        Roll back:  home-manager generations  (see the README)
MSG
