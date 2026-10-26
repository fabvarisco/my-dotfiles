#!/usr/bin/env python3
"""Keep unfocused windows translucent and draw a gray frame on the focused one."""

import json
import os
import signal
import subprocess

INACTIVE = 0.8
ACTIVE = 0.9


def discover_sway_socket():
    if os.environ.get("SWAYSOCK"):
        return
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    try:
        names = os.listdir(runtime)
    except OSError:
        return
    for name in names:
        if name.startswith("sway-ipc.") and name.endswith(".sock"):
            os.environ["SWAYSOCK"] = os.path.join(runtime, name)
            return


def take_pidfile():
    runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    path = os.path.join(runtime, "inactive-opacity.pid")
    if os.path.exists(path):
        try:
            old = int(open(path, encoding="utf-8").read().strip())
        except (OSError, ValueError):
            old = None
        if old and old != os.getpid():
            try:
                os.kill(old, signal.SIGTERM)
            except ProcessLookupError:
                pass
    with open(path, "w", encoding="utf-8") as handle:
        handle.write(str(os.getpid()))


def views(node, found):
    if node.get("pid") or node.get("app_id") or node.get("window_properties"):
        found.append(node)
    for key in ("nodes", "floating_nodes"):
        for child in node.get(key) or []:
            views(child, found)


def apply():
    raw = subprocess.check_output(["swaymsg", "-t", "get_tree"], text=True)
    found = []
    views(json.loads(raw), found)
    commands = []
    for window in found:
        focused = window.get("focused")
        opacity = ACTIVE if focused else INACTIVE
        border = "pixel 2" if focused else "none"
        commands.append(f'[con_id={window["id"]}] opacity {opacity}, border {border}')
    if commands:
        subprocess.run(["swaymsg", "; ".join(commands)], check=False)


def main():
    discover_sway_socket()
    if not os.environ.get("SWAYSOCK"):
        raise SystemExit("SWAYSOCK is not set and no sway socket was found")
    take_pidfile()
    apply()
    proc = subprocess.Popen(
        ["swaymsg", "-t", "subscribe", "-m", '["window"]'],
        stdout=subprocess.PIPE,
        text=True,
    )
    assert proc.stdout is not None
    for line in proc.stdout:
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if event.get("change") in {
            "focus",
            "new",
            "close",
            "move",
            "floating",
            "fullscreen_mode",
        }:
            apply()


if __name__ == "__main__":
    main()
