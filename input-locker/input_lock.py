#!/usr/bin/env python3
# pip install evdev
import datetime
import os
import select
import shutil
import subprocess
import sys

try:
    import evdev
except ImportError:
    print(
        "This script requires the 'evdev' library. Install it with 'pip install evdev'."
    )
    sys.exit(1)

import evdev

CTRL_KEYS = {evdev.ecodes.KEY_LEFTCTRL, evdev.ecodes.KEY_RIGHTCTRL}
META_KEYS = {evdev.ecodes.KEY_LEFTMETA, evdev.ecodes.KEY_RIGHTMETA}
BRACKET_KEY = evdev.ecodes.KEY_LEFTBRACE
LOG_FILE = "/tmp/lockdown.log"
FILE = "/tmp/lockdown.lock"
DMS_WIDGET = "intervalCommand:variant_1774169552473"


def print(*args, **kwargs):
    with open(LOG_FILE, "a") as f:
        timestampIso = datetime.datetime.now().isoformat()
        stamp = f"[{timestampIso}]"
        f.write(stamp + " ")
        f.write(" ".join(str(a) for a in args) + "\n")
    __builtins__.print(*args, **kwargs)


print("[ START ] input lockdown script started")
print(f"[ INFO ] aquiring lock {FILE}")

# check if already locked down
if os.path.exists(FILE):
    print(f"[ ERROR ] lock file {FILE} already exists. Is lockdown already active?")
    sys.exit(1)


def dms_ipc(action):
    if shutil.which("dms"):
        print(f"[ INFO ] sending DMS IPC command: {action}")
        subprocess.Popen(["dms", "ipc", "widget", action, DMS_WIDGET])


dms_ipc("status")

pressed = set()
devices = [evdev.InputDevice(p) for p in evdev.list_devices()]
grabs = []

print("[ LOCKDOWN ] grabbing input devices")

for dev in devices:
    try:
        dev.grab()
        grabs.append(dev)
        print(f"[ OK ] grabbed {dev.path} ({dev.name})")
    except Exception:
        pass

dms_ipc("reveal")
print("[ WAIT ] press Ctrl + Super + [ to unlock")

fdmap = {d.fd: d for d in grabs}

def on_exit():
    print("\n[ EXIT ] releasing input devices")
    for d in grabs:
        try:
            d.ungrab()
        except Exception:
            pass

    print(f"[ EXIT ] removing lock {FILE}")
    os.remove(FILE)
    dms_ipc("hide")

    sys.exit(0)


try:
    while True:
        r, _, _ = select.select(fdmap.keys(), [], [])

        # keep writing to a file so as to show that lockdown is active
        with open(FILE, "w") as f:
            f.write("LOCKDOWN ACTIVE\n")

        for fd in r:
            dev = fdmap[fd]
            for event in dev.read():
                if event.type != evdev.ecodes.EV_KEY:
                    continue

                key = evdev.categorize(event)
                code = key.scancode

                if key.keystate == key.key_down:
                    pressed.add(code)

                elif key.keystate == key.key_up:
                    pressed.discard(code)

                if (
                    any(k in pressed for k in CTRL_KEYS)
                    and any(k in pressed for k in META_KEYS)
                    and BRACKET_KEY in pressed
                ):
                    print("[ OK ] unlock combo detected")

                    on_exit()
except Exception as e:
    print(f"[ ERROR ] {e}")
    on_exit()
