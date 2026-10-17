# /// script
# requires-python = ">=3.11,<3.13"
# dependencies = ["py3dep", "pynhd", "numpy", "scipy", "matplotlib", "pillow", "pyproj"]
# ///
"""Braille contour logo of Tallulah Gorge for the server's fastfetch.

Reuses the wallpaper script's cached USGS lidar DEM. Each braille character is a
2x4 dot cell, so a 20x10-character logo is a 40x40-dot canvas.

    uv run server/fastfetch/make_logo.py            # writes logo.txt next to this file
    uv run server/fastfetch/make_logo.py --print    # just show it
"""
import argparse
import sys
from pathlib import Path

import numpy as np

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / "wallpapers"))
import topo_tallulah as topo  # noqa: E402  (shares DEM fetching + caching)

COLS, ROWS = 20, 10           # characters
SIDE_M = 2400                 # square crop on the ground, centred on the gorge
CENTER_OFFSET_M = (150, 0)    # nudge the crop (east, north) to frame the gorge
SMOOTH_M = 45                 # heavy smoothing: 40 dots can't show lidar detail
LINES = 5                     # roughly how many contour levels across the crop


def braille(dots):
    """dots: bool array (ROWS*4, COLS*2) -> list of strings."""
    bits = [(0, 0, 0x01), (1, 0, 0x02), (2, 0, 0x04), (0, 1, 0x08),
            (1, 1, 0x10), (2, 1, 0x20), (3, 0, 0x40), (3, 1, 0x80)]
    out = []
    for r in range(ROWS):
        line = ""
        for c in range(COLS):
            v = 0
            for dy, dx, b in bits:
                if dots[r * 4 + dy, c * 2 + dx]:
                    v |= b
            line += chr(0x2800 + v)
        out.append(line)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--print", action="store_true")
    ap.add_argument("--lines", type=int, default=LINES)
    ap.add_argument("--smooth", type=float, default=SMOOTH_M)
    ap.add_argument("--side", type=float, default=SIDE_M)
    args = ap.parse_args()

    from scipy.ndimage import gaussian_filter, map_coordinates
    frame = topo.frame_utm()
    x, y, z = topo.load_dem(topo.fetch_bbox(frame))
    res = abs(float(x[1] - x[0]))
    zs = gaussian_filter(np.where(np.isfinite(z), z, np.nanmean(z)), args.smooth / res)

    cx = (frame[0] + frame[2]) / 2 + CENTER_OFFSET_M[0]
    cy = (frame[1] + frame[3]) / 2 + CENTER_OFFSET_M[1]
    W, H = COLS * 2, ROWS * 4                       # dots
    px = cx - args.side / 2 + (np.arange(W) + 0.5) / W * args.side
    py = cy + args.side / 2 - (np.arange(H) + 0.5) / H * args.side
    rows = (py - y[0]) / (y[1] - y[0])
    cols = (px - x[0]) / (x[1] - x[0])
    rr, cc = np.meshgrid(rows, cols, indexing="ij")
    grid = map_coordinates(zs, [rr, cc], order=1, mode="nearest")

    interval = (grid.max() - grid.min()) / args.lines
    band = np.floor((grid - grid.min()) / interval).astype(int)
    dots = np.zeros_like(band, dtype=bool)
    dots[:, :-1] |= band[:, :-1] != band[:, 1:]     # band edge to the right
    dots[:-1, :] |= band[:-1, :] != band[1:, :]     # band edge below

    lines = braille(dots)
    text = "\n".join("$1" + l if i == 0 else l for i, l in enumerate(lines)) + "\n"
    if args.print:
        print("\n".join(lines))
    else:
        (HERE / "logo.txt").write_text(text)
        print("\n".join(lines))
        print(f"wrote {HERE / 'logo.txt'} ({COLS}x{ROWS}, interval {interval:.0f} m)")


if __name__ == "__main__":
    main()
