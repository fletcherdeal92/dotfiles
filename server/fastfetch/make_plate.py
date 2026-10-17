# /// script
# requires-python = ">=3.11"
# dependencies = ["pillow"]
# ///
"""The 'Petrichor' plate logo for the server's fastfetch: a sage Blue Ridge silhouette
over a name plate, in the Severance palette. Writes logo.txt using fastfetch's $N colour
markers ($1 sage, $2 muted, $3 text — set in config.jsonc).

    uv run server/fastfetch/make_plate.py              # write logo.txt
    uv run server/fastfetch/make_plate.py --preview out.png   # also render a PNG preview
"""
import argparse
import math
from pathlib import Path

HERE = Path(__file__).resolve().parent
W = 20                                   # inner width
RIDGE_ROWS = 4
NAME = "P E T R I C H O R"
COORDS = "34.73°N  83.39°W"              # Tallulah Gorge, Rabun County, GA
TAGLINE = "after the rain"
E = " ▁▂▃▄▅▆▇█"
COLORS = {"1": "#8C9F82", "2": "#4C566A", "3": "#C5C8C6"}   # preview only; fastfetch uses config


def ridge(c):
    """A small, soft Blue Ridge line low in the band (0..1 of its height); the space above is sky."""
    peak = lambda at, h, w: h * math.exp(-((c - at) / w) ** 2)
    return 0.10 + peak(2, 0.22, 3.0) + peak(11, 0.30, 4.5) + peak(19, 0.18, 2.0)


def lines():
    """List of rows; each row is a list of (colour, text) runs."""
    lv = RIDGE_ROWS * 8
    hs = [round(ridge(c) * lv) for c in range(W)]
    rows = [[("2", "╭" + "─" * (W + 2) + "╮")]]
    for r in range(RIDGE_ROWS):
        base = (RIDGE_ROWS - 1 - r) * 8
        cells = "".join(E[max(0, min(8, h - base))] for h in hs)
        rows.append([("2", "│ "), ("1", cells), ("2", " │")])
    text = lambda s, col="3": [("2", "│ "), (col, s.ljust(W)), ("2", " │")]
    rows += [text(""), text(NAME, "1"),
             [("2", "│ " + "─" * len(NAME) + " " * (W - len(NAME)) + " │")],
             text(COORDS), text(TAGLINE),
             [("2", "╰" + "─" * (W + 2) + "╯")]]
    return rows


def to_fastfetch(rows):
    out, last = [], None
    for row in rows:
        s = ""
        for col, txt in row:
            if col != last:
                s += f"${col}"; last = col
            s += txt
        out.append(s)
    return "\n".join(out) + "\n"


def preview(rows, path):
    from PIL import Image, ImageDraw, ImageFont
    font = ImageFont.truetype(str(Path.home() / "Library/Fonts/JetBrainsMonoNerdFontMono-Regular.ttf"), 30)
    cw, ch, pad = font.getbbox("█")[2], 40, 30
    img = Image.new("RGB", (pad * 2 + cw * (W + 4), pad * 2 + ch * len(rows)), "#0A0F14")
    d = ImageDraw.Draw(img)
    for r, row in enumerate(rows):
        x, y = pad, pad + r * ch
        for col, txt in row:
            for c in txt:
                if c in E[1:]:   # exact blocks; font glyphs leave hairline gaps
                    k = E.index(c); d.rectangle([x, y + ch - round(ch * k / 8), x + cw - 1, y + ch - 1], fill=COLORS[col])
                else:
                    d.text((x, y), c, font=font, fill=COLORS[col])
                x += cw
    img.save(path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--preview", metavar="PNG")
    args = ap.parse_args()
    rows = lines()
    (HERE / "logo.txt").write_text(to_fastfetch(rows))
    print("\n".join("".join(t for _, t in row) for row in rows))
    print(f"wrote {HERE / 'logo.txt'} ({len(rows)} lines)")
    if args.preview:
        preview(rows, args.preview); print(f"wrote {args.preview}")


if __name__ == "__main__":
    main()
