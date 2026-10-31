"""
CrazyGames Cover Generator / Resizer
Takes a master high-res artwork and exports the 3 mandatory CrazyGames covers:
- cover-landscape.png (1920x1080)
- cover-portrait.png (800x1200)
- cover-square.png (800x800)
"""

import argparse
import sys
from pathlib import Path

TARGETS = [
    ("cover-landscape.png", 1920, 1080),
    ("cover-portrait.png", 800, 1200),
    ("cover-square.png", 800, 800),
]

def crop_and_resize(img, target_w, target_h):
    from PIL import Image
    src_w, src_h = img.size
    target_ratio = target_w / target_h
    src_ratio = src_w / src_h

    if src_ratio > target_ratio:
        # Source is wider: crop sides
        crop_w = int(src_h * target_ratio)
        crop_h = src_h
        left = (src_w - crop_w) // 2
        top = 0
    else:
        # Source is taller: crop top/bottom
        crop_w = src_w
        crop_h = int(src_w / target_ratio)
        left = 0
        top = (src_h - crop_h) // 2

    box = (left, top, left + crop_w, top + crop_h)
    cropped = img.crop(box)
    resized = cropped.resize((target_w, target_h), Image.Resampling.LANCZOS)
    return resized

def generate_covers(input_path: str, output_dir: str):
    try:
        from PIL import Image
    except ImportError:
        print("[ERROR] Pillow is required to run this script. Run: pip install Pillow")
        sys.exit(1)

    in_file = Path(input_path)
    if not in_file.exists():
        print(f"[ERROR] Input file does not exist: {input_path}")
        sys.exit(1)

    out_path = Path(output_dir)
    out_path.mkdir(parents=True, exist_ok=True)

    print(f"Loading master image: {in_file.resolve()}")
    with Image.open(in_file) as master_img:
        master_img = master_img.convert("RGBA")
        print(f"Master size: {master_img.width}x{master_img.height} px")

        for filename, width, height in TARGETS:
            dest_file = out_path / filename
            print(f"Generating {filename} ({width}x{height} px)...")
            result = crop_and_resize(master_img, width, height)
            result.save(dest_file, "PNG", optimize=True)
            print(f"  -> Saved: {dest_file.resolve()}")

    print("\n[SUCCESS] Generated all 3 CrazyGames cover formats!")
    print("Reminder: Ensure the only text present on the image is the game title.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate CrazyGames covers from master art")
    parser.add_argument("input", help="Path to high-resolution master artwork")
    parser.add_argument("--out", default="./crazygames_covers", help="Output directory")
    args = parser.parse_args()
    generate_covers(args.input, args.out)
