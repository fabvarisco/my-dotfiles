#!/usr/bin/env python3
"""Load a web game at the official CrazyGames iframe sizes and collect screenshots + errors.

Usage: viewport_check.py URL [--out-dir shots] [--wait 6] [--raf-hz 144] [--click-center]

Writes one PNG per size (devicePixelRatio 1), contact_sheet.png (if Pillow is installed)
and report.json (console errors, page errors, failed requests, load time).
"""
import argparse
import json
import os
import sys
import time

SIZES = [
    (907, 510, "desktop-window"), (1216, 684, "desktop-window"),
    (1077, 606, "desktop-window"), (821, 462, "desktop-window"),
    (1366, 768, "desktop-fullscreen"), (1920, 1080, "desktop-fullscreen"),
    (1536, 864, "desktop-fullscreen"), (1280, 720, "desktop-fullscreen"),
    (800, 450, "mobile"), (1080, 607, "tablet"),
]

RAF_SCRIPT = """
((hz) => {
  const interval = 1000 / hz; const cbs = new Map(); let id = 0; let armed = false;
  function tick() {
    armed = false; const list = Array.from(cbs.entries()); cbs.clear(); const t = performance.now();
    for (const [, cb] of list) { try { cb(t); } catch (e) { console.error(e); } }
  }
  window.requestAnimationFrame = (cb) => {
    cbs.set(++id, cb); if (!armed) { armed = true; setTimeout(tick, interval); } return id;
  };
  window.cancelAnimationFrame = (i) => cbs.delete(i);
})(%s);
"""


def contact_sheet(shots, out_path, cell_w=480):
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return False
    thumbs = []
    for path, label in shots:
        im = Image.open(path).convert("RGB")
        h = int(im.height * cell_w / im.width)
        im = im.resize((cell_w, h))
        canvas = Image.new("RGB", (cell_w, h + 18), "white")
        canvas.paste(im, (0, 18))
        ImageDraw.Draw(canvas).text((4, 3), label, fill="black")
        thumbs.append(canvas)
    cols = 2
    rows = (len(thumbs) + cols - 1) // cols
    row_h = [max(t.height for t in thumbs[r * cols:(r + 1) * cols]) for r in range(rows)]
    sheet = Image.new("RGB", (cols * cell_w, sum(row_h)), "white")
    y = 0
    for r in range(rows):
        for c, t in enumerate(thumbs[r * cols:(r + 1) * cols]):
            sheet.paste(t, (c * cell_w, y))
        y += row_h[r]
    sheet.save(out_path)
    return True


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("url")
    ap.add_argument("--out-dir", default="shots")
    ap.add_argument("--wait", type=float, default=6.0, help="seconds to wait after load")
    ap.add_argument("--raf-hz", type=float, help="emulate requestAnimationFrame at this refresh rate")
    ap.add_argument("--click-center", action="store_true",
                    help="click the viewport center once, wait 2s, then capture (tests the 1-click rule)")
    args = ap.parse_args()

    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        sys.exit("Playwright for Python is required: pip install playwright && playwright install chromium")

    os.makedirs(args.out_dir, exist_ok=True)
    report = []
    shots = []
    with sync_playwright() as p:
        browser = p.chromium.launch(args=["--autoplay-policy=no-user-gesture-required"])
        for w, h, label in SIZES:
            touch = label in {"mobile", "tablet"}
            ctx = browser.new_context(viewport={"width": w, "height": h}, device_scale_factor=1,
                                      is_mobile=touch, has_touch=touch)
            if args.raf_hz:
                ctx.add_init_script(RAF_SCRIPT % args.raf_hz)
            page = ctx.new_page()
            entry = {"size": f"{w}x{h}", "label": label, "console_errors": [],
                     "page_errors": [], "failed_requests": [], "load_seconds": None}
            page.on("console", lambda m, e=entry: e["console_errors"].append(m.text[:300])
                    if m.type == "error" else None)
            page.on("pageerror", lambda err, e=entry: e["page_errors"].append(str(err)[:300]))
            page.on("requestfailed", lambda r, e=entry: e["failed_requests"].append(
                f"{r.url[:150]} ({r.failure})"))
            page.on("response", lambda r, e=entry: e["failed_requests"].append(
                f"{r.url[:150]} (HTTP {r.status})") if r.status >= 400 else None)
            t0 = time.time()
            try:
                page.goto(args.url, wait_until="load", timeout=60000)
                entry["load_seconds"] = round(time.time() - t0, 2)
            except Exception as exc:  # noqa: BLE001
                entry["page_errors"].append(f"navigation failed: {exc}"[:300])
            page.wait_for_timeout(int(args.wait * 1000))
            if args.click_center:
                page.mouse.click(w // 2, h // 2)
                page.wait_for_timeout(2000)
            name = f"{w}x{h}_{label}.png"
            path = os.path.join(args.out_dir, name)
            page.screenshot(path=path)
            shots.append((path, f"{w}x{h} {label}"))
            report.append(entry)
            ctx.close()
        browser.close()

    with open(os.path.join(args.out_dir, "report.json"), "w") as f:
        json.dump(report, f, indent=2)
    made = contact_sheet(shots, os.path.join(args.out_dir, "contact_sheet.png"))

    bad = False
    for e in report:
        issues = len(e["console_errors"]) + len(e["page_errors"]) + len(e["failed_requests"])
        bad = bad or bool(e["page_errors"])
        print(f"{e['size']:>10} {e['label']:<18} load={e['load_seconds']}s "
              f"console_errors={len(e['console_errors'])} page_errors={len(e['page_errors'])} "
              f"failed_requests={len(e['failed_requests'])}" + ("" if not issues else "  <-- see report.json"))
    print(f"\nScreenshots in {args.out_dir}/" + (" (contact_sheet.png for the overview)" if made else ""))
    print("Screenshots show the page at one moment only. Judge readability, HUD placement and "
          "whether gameplay (not a menu) is visible, by looking at them.")
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
