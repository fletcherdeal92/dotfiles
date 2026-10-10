# Generates severance-glow.png: python3 generate-glow.py severance-glow.png  (~20s, no dependencies)

import math, random, struct, sys, zlib

W, H = 3024, 1964
out = sys.argv[1]

BASE = (0x0A, 0x0F, 0x14)   # ghostty background
SAGE = (0x8C, 0x9F, 0x82)
BLUE = (0x81, 0xA1, 0xC1)

# soft glows: (cx, cy, radius, colour, strength)
glows = [
    (0.18 * W, 1.05 * H, 1.05 * H, SAGE, 0.24),
    (0.92 * W, -0.10 * H, 0.80 * H, BLUE, 0.07),
]

random.seed(7)
rows = bytearray()
for y in range(H):
    rows.append(0)  # PNG filter: none
    # darken toward the top so the bar blends in
    top = 1.0 - 0.35 * max(0.0, 1.0 - y / (0.18 * H)) ** 2
    for x in range(W):
        r, g, b = BASE
        for cx, cy, rad, col, s in glows:
            d = math.hypot(x - cx, y - cy) / rad
            if d < 1.0:
                t = s * (1.0 - d) ** 2.2
                r += (col[0] - r) * t
                g += (col[1] - g) * t
                b += (col[2] - b) * t
        n = random.random() - 0.5  # dither to avoid banding
        rows += bytes((
            max(0, min(255, int(r * top + n + 0.5))),
            max(0, min(255, int(g * top + n + 0.5))),
            max(0, min(255, int(b * top + n + 0.5))),
        ))

def chunk(tag, data):
    c = struct.pack(">I", len(data)) + tag + data
    return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(bytes(rows), 9))
png += chunk(b"IEND", b"")
open(out, "wb").write(png)
print("wrote", out, len(png) // 1024, "KB")
