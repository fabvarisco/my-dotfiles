#!/usr/bin/env bash
# Toggle recording / replay for gpu-screen-recorder.
# Replay mode requires -c since 6.x. The kernel comm is truncated to
# 15 characters, so the process name is gpu-screen-reco, not gpu-screen-rec.

set -u

comm=gpu-screen-reco
videos="${HOME}/Videos"
log="${XDG_STATE_HOME:-$HOME/.local/state}/hypr/gpu-screen.log"
mkdir -p "$videos" "$(dirname "$log")"

running() {
  pgrep -x "$comm" >/dev/null
}

focused_monitor() {
  hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' | head -n1
}

start() {
  local mon
  mon="$(focused_monitor)"
  if [[ -z "$mon" ]]; then
    notify-send "GPU Screen Recorder" "No focused monitor"
    return 1
  fi
  setsid -f gpu-screen-recorder "$@" -w "$mon" >>"$log" 2>&1
  sleep 0.4
  running
}

case "${1:-}" in
  replay-toggle)
    if running; then
      pkill -SIGINT -x "$comm"
      notify-send "Replay Buffer" "Stopped"
    elif start -c mp4 -f 60 -a default_output -r 60 -o "$videos"; then
      notify-send "Replay Buffer" "Started (60s)"
    else
      notify-send "Replay Buffer" "Failed to start"
    fi
    ;;
  replay-save)
    if running; then
      pkill -SIGUSR1 -x "$comm"
      notify-send "Replay" "Clip saved!"
    else
      notify-send "Replay" "No replay buffer running"
    fi
    ;;
  record-toggle)
    if running; then
      pkill -SIGINT -x "$comm"
      notify-send "Recording" "Stopped"
    elif start -c mp4 -f 60 -a default_output -o "$videos/recording_$(date +%Y%m%d_%H%M%S).mp4"; then
      notify-send "Recording" "Started"
    else
      notify-send "Recording" "Failed to start"
    fi
    ;;
  *)
    echo "usage: $0 replay-toggle|replay-save|record-toggle" >&2
    exit 1
    ;;
esac
