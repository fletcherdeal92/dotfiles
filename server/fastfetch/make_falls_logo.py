# /// script
# requires-python = ">=3.11"
# dependencies = ["numpy", "pillow"]
# ///
"""Braille logo of Tallulah Falls from a picture.

The committed logo.txt was made from a 19th-century hand-coloured lithograph of
Tallulah Falls, Georgia (Currier & Ives style, public domain); a reproduction's
product photo was the source and is not stored here. Light areas become dots, so on a dark terminal the
falls and cliffs glow and the woods stay dark. The source image is not committed.

    uv run server/fastfetch/make_falls_logo.py IMAGE [--print] [--mode threshold|atkinson|edges]

(make_logo.py is the older contour-map logo from the lidar DEM; either writes logo.txt.)
"""
import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageOps

HERE = Path(__file__).resolve().parent
COLS, ROWS = 22, 11                     # characters -> 44 x 44 dots, as tall as the info column
CROP = (0.28, 0.15, 0.86, 0.98)         # left, top, right, bottom fractions: falls + cliff face


def braille(dots):
    bits = [(0, 0, 0x01), (1, 0, 0x02), (2, 0, 0x04), (0, 1, 0x08),
            (1, 1, 0x10), (2, 1, 0x20), (3, 0, 0x40), (3, 1, 0x80)]
    return ["".join(chr(0x2800 + sum(b for dy, dx, b in bits if dots[r * 4 + dy, c * 2 + dx]))
                    for c in range(COLS)) for r in range(ROWS)]


def atkinson(g):
    """Atkinson dither (keeps highlights crisp, lets darks fall away)."""
    g = g.astype(np.float32).copy()
    out = np.zeros_like(g, dtype=bool)
    H, W = g.shape
    for y in range(H):
        for x in range(W):
            old = g[y, x]; new = 1.0 if old >= 0.5 else 0.0
            out[y, x] = new > 0
            err = (old - new) / 8
            for dx, dy in ((1, 0), (2, 0), (-1, 1), (0, 1), (1, 1), (0, 2)):
                if 0 <= x + dx < W and 0 <= y + dy < H:
                    g[y + dy, x + dx] += err
    return out


def main():
    global COLS, ROWS
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--print", action="store_true")
    ap.add_argument("--mode", default="threshold", choices=["atkinson", "threshold", "edges"])
    ap.add_argument("--gamma", type=float, default=1.6, help=">1 pushes mid-tones dark")
    ap.add_argument("--size", default=f"{COLS}x{ROWS}", help="characters, e.g. 22x11")
    ap.add_argument("--crop", default=",".join(map(str, CROP)), help="left,top,right,bottom fractions")
    ap.add_argument("--threshold", type=float, default=0.55)
    args = ap.parse_args()
    COLS, ROWS = map(int, args.size.split("x"))

    im = Image.open(args.image).convert("L")
    w, h = im.size
    l, t, r, b = map(float, args.crop.split(","))
    im = im.crop((int(l * w), int(t * h), int(r * w), int(b * h)))
    im = ImageOps.autocontrast(im, cutoff=2)
    if args.mode == "edges":
        im = im.filter(ImageFilter.FIND_EDGES)
        im = ImageOps.autocontrast(im, cutoff=4)
    im = im.resize((COLS * 2, ROWS * 4), Image.LANCZOS)
    g = (np.asarray(im, dtype=np.float32) / 255) ** args.gamma
    dots = atkinson(g) if args.mode == "atkinson" else g > (args.threshold if args.mode == "threshold" else 0.35)

    lines = braille(dots)
    print("\n".join(lines))
    if not args.print:
        (HERE / "logo.txt").write_text("$1" + "\n".join(lines) + "\n")
        print(f"wrote {HERE / 'logo.txt'}")


if __name__ == "__main__":
    main()
