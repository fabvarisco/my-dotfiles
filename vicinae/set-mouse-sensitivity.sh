#!/usr/bin/env bash
# @vicinae.schemaVersion 1
# @vicinae.title Set Mouse Sensitivity
# @vicinae.mode compact
# @vicinae.icon 🖱️
# @vicinae.description Set pointer acceleration from -1.0 (slower) to 1.0 (faster). Leave the field empty to show the current value.
# @vicinae.keywords ["mouse", "pointer", "accel", "speed"]
# @vicinae.argument1 { "type": "text", "placeholder": "-1.0 slower, 0 default, 1.0 faster", "optional": true }

set -eu

bin="$HOME/.nix-profile/bin/pointer-accel"
value="${1:-}"

if [ -z "$value" ]; then
  "$bin"
else
  "$bin" "$value"
fi
