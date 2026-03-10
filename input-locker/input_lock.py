#!/usr/bin/env python3
# pip install evdev
import select
import sys
import evdev

CTRL_KEYS = {evdev.ecodes.KEY_LEFTCTRL, evdev.ecodes.KEY_RIGHTCTRL}
META_KEYS = {evdev.ecodes.KEY_LEFTMETA, evdev.ecodes.KEY_RIGHTMETA}
BRACKET_KEY = evdev.ecodes.KEY_LEFTBRACE

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

print("[ WAIT ] press Ctrl + Super + [ to unlock")

fdmap = {d.fd: d for d in grabs}

while True:
    r, _, _ = select.select(fdmap.keys(), [], [])

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

                for d in grabs:
                    try:
                        d.ungrab()
                    except Exception:
                        pass

                sys.exit(0)
