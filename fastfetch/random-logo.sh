#!/usr/bin/env bash
# Random logo for fastfetch. Came from the fedora/sway branch.
# The built-in distro logo is ubuntu on this WSL branch.

# Directory of ASCII art files
ASCII_DIR="$HOME/.config/fastfetch/ascii-arts"

# ASCII files plus the Ubuntu logo (WSL). The Fedora branch used "fedora" here.
OPTIONS=()

# Add the ASCII files. -L follows Home Manager symlinks.
if [ -d "$ASCII_DIR" ]; then
    while IFS= read -r -d '' file; do
        OPTIONS+=("$file")
    done < <(find -L "$ASCII_DIR" -type f -name "*.txt" -print0)
fi

# Add the Ubuntu logo option
OPTIONS+=("ubuntu")

# Pick one option at random
RANDOM_CHOICE="${OPTIONS[$RANDOM % ${#OPTIONS[@]}]}"

# Run fastfetch with the chosen logo
if [ "$RANDOM_CHOICE" = "ubuntu" ]; then
    fastfetch --logo ubuntu
else
    fastfetch --logo "$RANDOM_CHOICE"
fi
