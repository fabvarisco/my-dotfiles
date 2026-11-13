#!/usr/bin/env python3
"""Redraw the chibi as truecolor half-block ANSI at another width.

Each output cell is one column and two pixels: ▀ uses the top pixel as the
foreground and the bottom pixel as the background. A transparent cell is a
space. The committed assets/byanca-chibi.ans is the original art; this script
is only for regenerating a size. Needs Pillow.

    python3 assets/gen-chibi.py assets/byanca-chibi.png -o /tmp/chibi.ans --width 48
"""

from __future__ import annotations

import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("png", type=Path)
    parser.add_argument("-o", "--output", type=Path, required=True)
    parser.add_argument("--width", type=int, default=48)
    parser.add_argument("--alpha", type=int, default=24, help="alpha below this is empty")
    args = parser.parse_args()

    try:
        from PIL import Image
    except ImportError as err:
        raise SystemExit("Pillow is required (python3-pil)") from err

    image = Image.open(args.png).convert("RGBA")
    width = args.width
    height = max(2, round(image.height * width / image.width))
    if height % 2:
        height += 1
    image = image.resize((width, height), Image.Resampling.BOX)

    def opaque(pixel: tuple[int, int, int, int]) -> bool:
        return pixel[3] >= args.alpha

    def fg(pixel: tuple[int, int, int, int]) -> str:
        return f"38;2;{pixel[0]};{pixel[1]};{pixel[2]}"

    def bg(pixel: tuple[int, int, int, int]) -> str:
        return f"48;2;{pixel[0]};{pixel[1]};{pixel[2]}"

    rows: list[str] = []
    for y in range(0, height, 2):
        cells: list[str] = []
        for x in range(width):
            top = image.getpixel((x, y))
            bottom = image.getpixel((x, y + 1))
            top_on = opaque(top)
            bottom_on = opaque(bottom)
            if top_on and bottom_on:
                cells.append(f"\033[{fg(top)};{bg(bottom)}m▀\033[0m")
            elif top_on:
                cells.append(f"\033[{fg(top)}m▀\033[0m")
            elif bottom_on:
                cells.append(f"\033[{fg(bottom)}m▄\033[0m")
            else:
                cells.append(" ")
        rows.append("".join(cells).rstrip(" "))
    args.output.write_text("\n".join(rows) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
