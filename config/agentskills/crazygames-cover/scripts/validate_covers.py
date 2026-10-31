"""
CrazyGames Cover Validator
Validates image files against official CrazyGames specifications:
- Landscape: 1920x1080 (16:9)
- Portrait: 800x1200 (2:3)
- Square: 800x800 (1:1)
"""

import sys
import os
import argparse
from pathlib import Path

REQUIRED_SPECS = {
    "landscape": {
        "width": 1920,
        "height": 1080,
        "ratio": (16, 9),
        "aliases": ["landscape", "16-9", "16x9", "wide", "horizontal"]
    },
    "portrait": {
        "width": 800,
        "height": 1200,
        "ratio": (2, 3),
        "aliases": ["portrait", "2-3", "2x3", "vertical", "tall"]
    },
    "square": {
        "width": 800,
        "height": 800,
        "ratio": (1, 1),
        "aliases": ["square", "1-1", "1x1", "box", "thumb"]
    }
}

def get_image_dimensions(image_path: Path):
    try:
        from PIL import Image
        with Image.open(image_path) as img:
            return img.size  # (width, height)
    except ImportError:
        # Fallback reading dimensions without PIL for PNG/JPEG headers
        import struct
        with open(image_path, "rb") as f:
            data = f.read(64)
            # PNG check
            if data[:8] == b"\x89PNG\r\n\x1a\n":
                w, h = struct.unpack(">LL", data[16:24])
                return w, h
            # For general files, recommend installing pillow
            raise RuntimeError("Pillow is required for non-PNG format checks. Install via: pip install Pillow")

def match_target_type(filename: str):
    fname = filename.lower()
    for cover_type, spec in REQUIRED_SPECS.items():
        for alias in spec["aliases"]:
            if alias in fname:
                return cover_type
    return None

def validate_directory(target_dir: str):
    dir_path = Path(target_dir)
    if not dir_path.is_dir():
        print(f"[ERROR] Directory does not exist: {target_dir}")
        return False

    image_extensions = {".png", ".jpg", ".jpeg", ".webp"}
    found_files = [p for p in dir_path.iterdir() if p.suffix.lower() in image_extensions]

    if not found_files:
        print(f"[WARNING] No image files found in {target_dir}")
        return False

    print("=" * 60)
    print(" CrazyGames Cover Validation Report")
    print(f" Directory: {dir_path.resolve()}")
    print("=" * 60)

    validated_types = {}
    has_errors = False

    for img_path in sorted(found_files):
        try:
            w, h = get_image_dimensions(img_path)
            file_kb = img_path.stat().st_size / 1024
            detected_type = match_target_type(img_path.name)
            
            status = "UNKNOWN"
            details = []

            for cover_type, spec in REQUIRED_SPECS.items():
                if w == spec["width"] and h == spec["height"]:
                    status = f"PASS ({cover_type.upper()})"
                    validated_types[cover_type] = img_path.name
                    break
            
            if "PASS" not in status:
                has_errors = True
                status = "FAIL"
                if detected_type:
                    expected = REQUIRED_SPECS[detected_type]
                    details.append(
                        f"Expected {expected['width']}x{expected['height']} for '{detected_type}', got {w}x{h}"
                    )
                else:
                    details.append(
                        f"Dimensions {w}x{h} do not match any CrazyGames format (1920x1080, 800x1200, 800x800)"
                    )

            print(f"\n[{status}] {img_path.name}")
            print(f"  Dimensions: {w} x {h} px | Size: {file_kb:.1f} KB")
            for d in details:
                print(f"  -> {d}")

        except Exception as e:
            print(f"\n[ERROR] Could not read {img_path.name}: {e}")
            has_errors = True

    print("\n" + "-" * 60)
    print(" CrazyGames Submission Readiness:")
    print("-" * 60)
    all_present = True
    for req in ["landscape", "portrait", "square"]:
        if req in validated_types:
            print(f"  [OK] {req.capitalize()}: {validated_types[req]}")
        else:
            print(f"  [MISSING] {req.capitalize()} cover is missing!")
            all_present = False

    print("-" * 60)
    if all_present and not has_errors:
        print("RESULT: ALL COVERS MEET CRAZYGAMES SPECIFICATIONS!")
        return True
    else:
        print("RESULT: ISSUES DETECTED. Please fix dimensions before submitting.")
        return False

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Validate CrazyGames covers")
    parser.add_argument("--dir", default=".", help="Directory containing covers")
    args = parser.parse_args()
    success = validate_directory(args.dir)
    sys.exit(0 if success else 1)
