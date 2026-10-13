#!/usr/bin/env bash

# Force C locale for consistent decimal formatting
export LC_NUMERIC=C

# Get current sensitivity
current=$(hyprctl getoption input:sensitivity -j | jq -r '.float')
current_display=$(printf "%.1f" "$current")

echo ""
gum style --foreground 212 --bold "Mouse Sensitivity"
echo ""
echo "Current: $current_display"
echo ""

# Options from -1.0 to 1.0
options="-1.0
-0.8
-0.6
-0.4
-0.2
0.0
0.2
0.4
0.6
0.8
1.0"

# Show selection menu
selected=$(echo "$options" | gum choose --header "Select sensitivity:" --cursor.foreground 212)

# Check if user cancelled
if [ -z "$selected" ]; then
    exit 0
fi

# Apply sensitivity. hyprctl keyword was removed in Hyprland 0.56.
hyprctl eval "hl.config({ input = { sensitivity = ${selected} } })"

# Save for persistence across reboots (using writable location)
mkdir -p ~/.local/state/hypr
echo "$selected" > ~/.local/state/hypr/mouse-sensitivity

echo ""
gum style --foreground 120 "Applied: $selected (saved)"
sleep 1
