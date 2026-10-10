#!/usr/bin/env python3
"""Car-stereo style marquee for a sketchybar label.

Shows the first WIDTH characters for HOLD seconds, scrolls through the
text once (wrapping back to the start), then holds again. Runs until
killed; front_app.sh restarts it whenever the title changes.

usage: marquee.py <item> <text>
"""
import subprocess
import sys
import time

WIDTH = 40      # visible characters (matches label.max_chars)
HOLD = 20.0     # seconds to rest on the beginning
STEP = 0.085    # seconds per character (~12 chars/s)
GAP = "   •   "

item, text = sys.argv[1], sys.argv[2]
loop = text + GAP
strip = loop + loop


def show(offset):
    window = strip[offset:offset + WIDTH]
    subprocess.run(["sketchybar", "--set", item, f"label={window}"], check=False)


while True:
    time.sleep(HOLD)
    for offset in range(1, len(loop) + 1):
        show(offset % len(loop))
        time.sleep(STEP)
