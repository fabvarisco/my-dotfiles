#!/usr/bin/env bash
# Cycle to the next wallpaper in ~/.config/walls (non-interactive).

set -u

WALLPAPER_DIR="$HOME/.config/walls"
CACHE_FILE="$HOME/.cache/hypr/current_wallpaper"

if [ ! -d "$WALLPAPER_DIR" ]; then
  notify-send "Wallpaper Error" "Directory not found: $WALLPAPER_DIR"
  exit 1
fi

mapfile -t WALLPAPERS < <(
  find -L "$WALLPAPER_DIR" \( -type f -o -type l \) \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    | sort
)

if [ ${#WALLPAPERS[@]} -eq 0 ]; then
  notify-send "Wallpaper Error" "No wallpapers found in $WALLPAPER_DIR"
  exit 1
fi

current=""
if [ -f "$CACHE_FILE" ]; then
  current="$(cat "$CACHE_FILE")"
fi

next_index=0
if [ -n "$current" ]; then
  for i in "${!WALLPAPERS[@]}"; do
    if [ "${WALLPAPERS[$i]}" = "$current" ]; then
      next_index=$(( (i + 1) % ${#WALLPAPERS[@]} ))
      break
    fi
  done
fi

SELECTED_WALL="${WALLPAPERS[$next_index]}"

hyprctl monitors -j | jq -r '.[].name' | while read -r mon; do
  [ -n "$mon" ] || continue
  noctalia-shell ipc call wallpaper set "$SELECTED_WALL" "$mon"
done

mkdir -p "$(dirname "$CACHE_FILE")"
echo "$SELECTED_WALL" >"$CACHE_FILE"

# Keep StreamController Wall key thumbnail in sync.
# SC skips --change-page when already on Beelink and caches Page JSON in memory,
# so we point the key at a fixed symlink and force a blank→Beelink page bounce
# (Image.open re-reads the symlink target on reload).
ICONS_DIR="$HOME/.config/hypr/streamdeck-icons"
WALL_ICON="$ICONS_DIR/wall-current.jpg"
DECK_SERIAL="A00DA6191LL9"
mkdir -p "$ICONS_DIR"
ln -sfn "$SELECTED_WALL" "$WALL_ICON"

if command -v streamcontroller >/dev/null 2>&1; then
  streamcontroller --change-page "$DECK_SERIAL" _blank >/dev/null 2>&1 || true
  # Brief pause so the blank page fully replaces Beelink before bouncing back.
  sleep 0.15
  streamcontroller --change-page "$DECK_SERIAL" Beelink >/dev/null 2>&1 || true
fi

notify-send "Wallpaper Changed" "$(basename "$SELECTED_WALL")"