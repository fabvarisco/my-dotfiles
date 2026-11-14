#!/usr/bin/env bash
# Toggle special:comms; launch Vesktop / TeamSpeak if needed.

set -u

if ! pgrep -x vesktop >/dev/null; then
  setsid -f vesktop >/dev/null 2>&1
fi

if ! pgrep -x TeamSpeak >/dev/null; then
  setsid -f TeamSpeak >/dev/null 2>&1
fi

hyprctl dispatch togglespecialworkspace comms
