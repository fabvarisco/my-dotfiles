#!/usr/bin/env python3
"""Static scan of a game project or web build for CrazyGames gameplay-requirement signals.

Usage: static_audit.py DIR [--json]

Hits are evidence to inspect, not verdicts. Exit code is 1 if any FAIL is found.
"""
import argparse
import json
import os
import re
import sys

SKIP_DIRS = {"node_modules", ".git", ".godot", ".import", ".idea", ".vscode",
             "__pycache__", "Library", "Temp", "obj", "bin"}
TEXT_EXT = {".html", ".htm", ".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx", ".css",
            ".json", ".gd", ".cs", ".tscn", ".tres", ".cfg", ".godot", ".csv", ".po"}
MAX_BYTES = 3_000_000
SKIP_NAMES = re.compile(r"(package-lock|yarn\.lock)|(crazygames.*sdk|sdk.*crazygames)", re.I)

# (id, severity, regex, requirement, message)
LINE_RULES = [
    ("custom-fullscreen", "REVIEW",
     r"requestFullscreen|webkitRequestFullscreen|mozRequestFullScreen|exitFullscreen"
     r"|WINDOW_MODE_(EXCLUSIVE_)?FULLSCREEN|Screen\.fullScreen\s*=|Screen\.SetResolution\([^)]*true",
     "No custom fullscreen button",
     "Fullscreen API used; CrazyGames provides fullscreen and custom buttons are prohibited"),
    ("store-link", "FAIL",
     r"play\.google\.com/store|apps\.apple\.com|itunes\.apple\.com",
     "No cross-promotion",
     "App Store / Google Play link; never allowed in-game (use Developer Portal metadata)"),
    ("external-link", "REVIEW",
     r"itch\.io|store\.steampowered\.com|steamcommunity\.com|epicgames\.com|discord\.(gg|com)"
     r"|(?<!sdk\.)crazygames\.com|poki\.com|kongregate\.com|newgrounds\.com|y8\.com|gamejolt\.com"
     r"|OS\.shell_open|window\.open\(|JavaScriptBridge",
     "No cross-promotion",
     "External link or promo target; allowed only in the documented exceptions and never as the main menu CTA"),
    ("escape-key", "REVIEW",
     r"""(key|code)\s*={2,3}\s*['"](Escape|Esc)['"]|keyCode\s*={2,3}\s*27|KEY_ESCAPE|KeyCode\.Escape|ui_cancel""",
     "Intuitive controls / restricted keys",
     "Escape is bound; it exits fullscreen on the web, so core actions should not depend on it"),
    ("ctrl-w", "REVIEW",
     r"""(ctrlKey|metaKey)[^\n]{0,60}['"]w['"]|['"]w['"][^\n]{0,60}(ctrlKey|metaKey)""",
     "Intuitive controls / restricted keys",
     "Ctrl/Cmd+W closes the tab; avoid binding it"),
    ("layout-key", "REVIEW",
     r"""\bkey\s*={2,3}\s*['"][wasdWASD]['"]|keyCode\s*={2,3}\s*(87|65|83|68)\b|which\s*={2,3}\s*(87|65|83|68)\b""",
     "Keyboard layout",
     "Letter-based key check breaks on AZERTY (ZQSD); bind by event.code / physical key instead"),
    ("hardcoded-key-hint", "INFO",
     r"""['"`>](Press|Use)\s+(W|A|S|D|WASD|W\/A\/S\/D)\b""",
     "Keyboard layout",
     "Hard-coded WASD hint; consider showing the key label from the user's layout"),
]

# Block heuristics for frame-rate dependent movement
JS_FRAME_TOKENS = re.compile(r"delta|\bdt\b|performance\.now|Date\.now|timestamp|elapsed|\bnow\b|fixed|accumulator", re.I)
MOVE_PATTERN = re.compile(r"(\w+(\.\w+)*)\s*[+-]=\s*[\w.()]+")


def iter_files(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for name in filenames:
            ext = os.path.splitext(name)[1].lower()
            if ext not in TEXT_EXT or SKIP_NAMES.search(name):
                continue
            path = os.path.join(dirpath, name)
            try:
                if os.path.getsize(path) > MAX_BYTES:
                    continue
                with open(path, "r", encoding="utf-8", errors="ignore") as f:
                    yield path, f.read()
            except OSError:
                continue


def snippet(line, m):
    s = max(0, m.start() - 40)
    return line[s:m.end() + 60].strip()[:140]


def func_blocks(text, header_re, lang):
    """Yield (start_line, name, body) for GDScript (indent) or C# (brace) methods."""
    lines = text.splitlines()
    if lang == "gd":
        i = 0
        while i < len(lines):
            m = re.match(r"\s*func\s+(\w+)\s*\(", lines[i])
            if m and header_re.fullmatch(m.group(1)):
                base = len(lines[i]) - len(lines[i].lstrip())
                j = i + 1
                while j < len(lines) and (not lines[j].strip() or
                                          len(lines[j]) - len(lines[j].lstrip()) > base):
                    j += 1
                yield i + 1, m.group(1), "\n".join(lines[i:j])
                i = j
            else:
                i += 1
    else:
        for m in re.finditer(r"void\s+(\w+)\s*\([^)]*\)\s*\{", text):
            if not header_re.fullmatch(m.group(1)):
                continue
            depth, k = 1, m.end()
            while k < len(text) and depth:
                depth += (text[k] == "{") - (text[k] == "}")
                k += 1
            yield text.count("\n", 0, m.start()) + 1, m.group(1), text[m.start():k]


def scan(root):
    findings = []
    presence = {"sdk": [], "sdk_locale": [], "translation": []}

    def add(sev, rule, req, path, line, msg, snip=""):
        findings.append({"severity": sev, "rule": rule, "requirement": req,
                         "file": os.path.relpath(path, root), "line": line,
                         "message": msg, "snippet": snip})

    for path, text in iter_files(root):
        ext = os.path.splitext(path)[1].lower()
        rel = os.path.relpath(path, root)
        lines = text.splitlines()
        for ln, line in enumerate(lines, 1):
            for rid, sev, rx, req, msg in LINE_RULES:
                m = re.search(rx, line)
                if m:
                    add(sev, rid, req, path, ln, msg, snippet(line, m))
            if re.search(r"CrazyGames\.SDK|sdk\.crazygames\.com|crazygames-sdk|CrazySDK", line):
                presence["sdk"].append(rel)
            if "systemInfo" in line:
                presence["sdk_locale"].append(rel)
            if re.search(r"i18n|localiz|TranslationServer|\.translations|translations\s*[=:]|locale", line, re.I):
                presence["translation"].append(rel)

        # frame-rate dependence heuristics
        if ext in {".js", ".mjs", ".ts", ".jsx", ".tsx", ".html", ".htm"}:
            if "requestAnimationFrame" in text and not JS_FRAME_TOKENS.search(text):
                ln = next(i for i, l in enumerate(lines, 1) if "requestAnimationFrame" in l)
                add("REVIEW", "raf-no-delta", "Consistent physics", path, ln,
                    "requestAnimationFrame loop with no delta-time/timestamp tokens in the file; "
                    "movement may scale with refresh rate", "")
        elif ext == ".gd":
            for ln, name, body in func_blocks(text, re.compile(r"_process"), "gd"):
                inner = body.split("\n", 1)[1] if "\n" in body else ""
                if MOVE_PATTERN.search(inner) and "delta" not in inner:
                    add("REVIEW", "process-no-delta", "Consistent physics", path, ln,
                        "_process() changes a value with += / -= and never uses delta; "
                        "use delta or move simulation to _physics_process()", "")
        elif ext == ".cs":
            for ln, name, body in func_blocks(text, re.compile(r"Update"), "cs"):
                if MOVE_PATTERN.search(body) and "deltaTime" not in body and "fixedDeltaTime" not in body:
                    add("REVIEW", "update-no-delta", "Consistent physics", path, ln,
                        "Update() changes a value with += / -= without Time.deltaTime; "
                        "scale by deltaTime or use FixedUpdate()", "")

    # presence checks
    uniq = lambda xs: sorted(set(xs))
    if presence["sdk"] and presence["translation"] and not presence["sdk_locale"]:
        findings.append({"severity": "REVIEW", "rule": "locale-not-from-sdk",
                         "requirement": "Language support", "file": "-", "line": 0,
                         "message": "Translation code found (" + ", ".join(uniq(presence["translation"])[:3]) +
                                    ") but nothing reads the SDK systemInfo.locale; language should follow "
                                    "the SDK locale with English fallback", "snippet": ""})
    if not presence["translation"]:
        findings.append({"severity": "INFO", "rule": "no-translation-code", "requirement": "Language support",
                         "file": "-", "line": 0,
                         "message": "No localization code detected; fine if the game is English-only, "
                                    "but confirm all visible text is in English", "snippet": ""})
    if not presence["sdk"]:
        findings.append({"severity": "INFO", "rule": "no-sdk", "requirement": "Language support",
                         "file": "-", "line": 0,
                         "message": "CrazyGames SDK not referenced; locale check skipped (SDK is optional in "
                                    "Basic launch, required in Full)", "snippet": ""})
    return findings


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("directory")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()
    if not os.path.isdir(args.directory):
        sys.exit(f"Not a directory: {args.directory}")
    findings = scan(args.directory)
    order = {"FAIL": 0, "REVIEW": 1, "INFO": 2}
    findings.sort(key=lambda f: (order[f["severity"]], f["requirement"], f["file"], f["line"]))
    if args.json:
        print(json.dumps(findings, indent=2))
    else:
        if not findings:
            print("No signals found. This does not prove compliance; run the viewport check "
                  "and the manual checklist.")
        for f in findings:
            loc = f"{f['file']}:{f['line']}" if f["line"] else f["file"]
            print(f"{f['severity']:<6} [{f['requirement']}] {f['rule']} @ {loc}")
            print(f"       {f['message']}")
            if f["snippet"]:
                print(f"       > {f['snippet']}")
        counts = {s: sum(1 for f in findings if f["severity"] == s) for s in order}
        print(f"\n{counts['FAIL']} FAIL, {counts['REVIEW']} REVIEW, {counts['INFO']} INFO")
    sys.exit(1 if any(f["severity"] == "FAIL" for f in findings) else 0)


if __name__ == "__main__":
    main()
