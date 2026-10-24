#!/usr/bin/env bash

# Directory of ASCII art files
ASCII_DIR="$HOME/.config/fastfetch/ascii-arts"

# ASCII files plus the Fedora logo
OPTIONS=()

# Add the ASCII files. -L follows Home Manager symlinks.
if [ -d "$ASCII_DIR" ]; then
    while IFS= read -r -d '' file; do
        OPTIONS+=("$file")
    done < <(find -L "$ASCII_DIR" -type f -name "*.txt" -print0)
fi

# Add the Fedora logo option
OPTIONS+=("fedora")

# Pick one option at random
RANDOM_CHOICE="${OPTIONS[$RANDOM % ${#OPTIONS[@]}]}"

# Run fastfetch with the chosen logo
if [ "$RANDOM_CHOICE" = "fedora" ]; then
    fastfetch --logo fedora
else
    fastfetch --logo "$RANDOM_CHOICE"
fi
