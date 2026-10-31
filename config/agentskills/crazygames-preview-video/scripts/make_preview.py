#!/usr/bin/env python3
"""Build and validate CrazyGames hover preview videos.

  make_preview.py make  SOURCE --cover-landscape L.png --cover-portrait P.png [opts]
  make_preview.py check VIDEO [VIDEO ...] [--portrait-size WxH]

Requires ffmpeg and ffprobe on PATH.
"""
import argparse
import json
import os
import re
import subprocess
import sys

LANDSCAPE = (1920, 1080)
PORTRAIT = (1080, 1620)
MAX_SECONDS = 20.0
MIN_SECONDS = 15.0
MAX_MB = 50.0
FPS = 30


def run(cmd, capture=False):
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        sys.exit("Command failed:\n  " + " ".join(cmd) + "\n" + res.stderr[-2000:])
    return res


def probe(path):
    out = run(["ffprobe", "-v", "error", "-print_format", "json",
               "-show_format", "-show_streams", path]).stdout
    return json.loads(out)


def parse_size(text):
    m = re.fullmatch(r"(\d+)x(\d+)", text)
    if not m:
        sys.exit(f"Invalid size '{text}', expected WxH")
    return int(m.group(1)), int(m.group(2))


def fill_filter(w, h, focus=0.5):
    """Scale to cover the target box, then crop (never letterbox)."""
    return (f"scale={w}:{h}:force_original_aspect_ratio=increase,"
            f"crop={w}:{h}:x='(iw-{w})*{focus}':y='(ih-{h})/2',setsar=1,fps={FPS},format=yuv420p")


def encode(source, cover, size, start, duration, hold, fade, focus, crf, out):
    w, h = size
    filt = (
        f"[0:v]{fill_filter(w, h)}[c];"
        f"[1:v]trim=start={start}:duration={duration},setpts=PTS-STARTPTS,"
        f"{fill_filter(w, h, focus)}[v];"
        f"[c][v]xfade=transition=fade:duration={fade}:offset={hold}[out]"
    )
    cmd = ["ffmpeg", "-y", "-v", "error",
           "-loop", "1", "-t", str(hold + fade), "-i", cover,
           "-i", source,
           "-filter_complex", filt, "-map", "[out]",
           "-an", "-c:v", "libx264", "-preset", "slow", "-crf", str(crf),
           "-pix_fmt", "yuv420p", "-movflags", "+faststart", out]
    run(cmd)


def build(args):
    if not os.path.exists(args.source):
        sys.exit(f"Source not found: {args.source}")
    os.makedirs(args.out_dir, exist_ok=True)
    # total = hold + clip (xfade overlaps by `fade`, so clip length drives the rest)
    duration = min(args.duration, MAX_SECONDS - args.hold)
    jobs = [
        ("landscape", LANDSCAPE, args.cover_landscape, args.source, 0.5),
        ("portrait", parse_size(args.portrait_size), args.cover_portrait,
         args.portrait_source or args.source, args.crop_focus),
    ]
    outputs = []
    for name, size, cover, src, focus in jobs:
        if not cover or not os.path.exists(cover):
            sys.exit(f"Missing {name} cover image: {cover}")
        out = os.path.join(args.out_dir, f"preview_{name}.mp4")
        for crf in (20, 23, 26, 29, 32):
            encode(src, cover, size, args.start, duration, args.hold, args.fade,
                   focus, crf, out)
            mb = os.path.getsize(out) / 1e6
            if mb <= args.max_mb:
                break
            print(f"[{name}] {mb:.1f} MB at crf {crf}, retrying smaller...")
        else:
            print(f"[{name}] WARNING: still above {args.max_mb} MB at crf 32")
        outputs.append(out)
        print(f"[{name}] wrote {out} ({os.path.getsize(out) / 1e6:.1f} MB)")
    print()
    return check(outputs, args.portrait_size)


def detect_bars(path, w, h):
    """Return (black_frames_found, bars_detected) using ffmpeg filters."""
    res = subprocess.run(
        ["ffmpeg", "-v", "info", "-i", path, "-vf",
         "cropdetect=limit=24:round=2:reset=0,blackdetect=d=0.2:pix_th=0.05",
         "-an", "-f", "null", "-"],
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    err = res.stderr
    crops = re.findall(r"crop=(\d+):(\d+):(\d+):(\d+)", err)
    bars = False
    if crops:
        # use the most common detected crop after the cover section
        cw, ch, _, _ = map(int, max(set(crops), key=crops.count))
        bars = cw < w * 0.97 or ch < h * 0.97
    black = re.findall(r"black_start:([\d.]+)\s+black_end:([\d.]+)", err)
    return black, bars


def check(paths, portrait_size="1080x1620"):
    portrait = parse_size(portrait_size)
    failed = False
    for path in paths:
        info = probe(path)
        v = next((s for s in info["streams"] if s["codec_type"] == "video"), None)
        has_audio = any(s["codec_type"] == "audio" for s in info["streams"])
        if not v:
            print(f"FAIL {path}: no video stream")
            failed = True
            continue
        w, h = v["width"], v["height"]
        dur = float(info["format"]["duration"])
        mb = os.path.getsize(path) / 1e6
        orient = "landscape" if w >= h else "portrait"
        want = LANDSCAPE if orient == "landscape" else portrait
        problems, warns = [], []
        if (w, h) != want:
            problems.append(f"resolution {w}x{h}, expected {want[0]}x{want[1]}")
        if dur > MAX_SECONDS + 0.05:
            problems.append(f"duration {dur:.1f}s > {MAX_SECONDS:.0f}s")
        if dur < MIN_SECONDS - 0.5:
            warns.append(f"duration {dur:.1f}s is under the suggested {MIN_SECONDS:.0f}s")
        if mb > MAX_MB:
            problems.append(f"size {mb:.1f} MB > {MAX_MB:.0f} MB")
        if has_audio:
            problems.append("has an audio track (must be silent)")
        black, bars = detect_bars(path, w, h)
        if bars:
            warns.append("possible black bars detected (verify visually)")
        if black:
            spans = ", ".join(f"{a}-{b}s" for a, b in black[:3])
            warns.append(f"black frames at {spans}")
        status = "FAIL" if problems else "OK  "
        print(f"{status} {os.path.basename(path)} [{orient}] {w}x{h} {dur:.1f}s {mb:.1f} MB")
        for p in problems:
            print(f"     - {p}")
        for wmsg in warns:
            print(f"     ! {wmsg}")
        failed = failed or bool(problems)
    print("\nNot checkable automatically: mouse cursor, burned-in text, misleading "
          "content, whether frame 0 matches the cover. Inspect frames manually.")
    return 1 if failed else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)

    m = sub.add_parser("make", help="build landscape + portrait previews")
    m.add_argument("source")
    m.add_argument("--cover-landscape", required=True)
    m.add_argument("--cover-portrait", required=True)
    m.add_argument("--portrait-source", help="dedicated portrait recording (optional)")
    m.add_argument("--start", type=float, default=0.0, help="start time in source (s)")
    m.add_argument("--duration", type=float, default=18.0, help="gameplay seconds")
    m.add_argument("--hold", type=float, default=0.3, help="seconds the cover is shown")
    m.add_argument("--fade", type=float, default=0.25, help="cover to gameplay crossfade (s)")
    m.add_argument("--crop-focus", type=float, default=0.5,
                   help="0..1 horizontal slice kept when cropping to portrait")
    m.add_argument("--portrait-size", default="1080x1620")
    m.add_argument("--max-mb", type=float, default=MAX_MB)
    m.add_argument("--out-dir", default="out")

    c = sub.add_parser("check", help="validate existing videos")
    c.add_argument("videos", nargs="+")
    c.add_argument("--portrait-size", default="1080x1620")

    args = ap.parse_args()
    if args.cmd == "make":
        sys.exit(build(args))
    sys.exit(check(args.videos, args.portrait_size))


if __name__ == "__main__":
    main()
