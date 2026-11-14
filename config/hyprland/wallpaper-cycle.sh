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
notify-send "Wallpaper Changed" "$(basename "$SELECTED_WALL")"
