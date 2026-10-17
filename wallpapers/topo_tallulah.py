# /// script
# requires-python = ">=3.11,<3.13"
# dependencies = ["py3dep", "pynhd", "numpy", "scipy", "matplotlib", "pillow", "pyproj", "astral"]
# ///
"""Topographic contour wallpaper of Tallulah Gorge (Tallulah Falls, GA).

Real USGS 3DEP elevation (1 m lidar where available), reprojected to UTM 17N
and drawn in the Severance palette. Optional NHD Tallulah River overlay.

    uv run wallpapers/topo_tallulah.py                 # 1x + 2x PNGs next to this file
    uv run wallpapers/topo_tallulah.py --interval 10   # try another contour interval
    uv run wallpapers/topo_tallulah.py --coords        # add the coordinate caption
    uv run wallpapers/topo_tallulah.py --river         # overlay the NHD Tallulah River
    uv run wallpapers/topo_tallulah.py --dynamic       # solar dynamic .heic (hillshade follows the sun)
    uv run wallpapers/topo_tallulah.py --dynamic --strength 0.1 --preview   # + contact sheet of all frames

Raw data is cached in ~/.cache/rice-topo, so reruns don't re-download.
"""
import argparse
import hashlib
import os
from pathlib import Path

import numpy as np

# ---------------------------------------------------------------- tweak me
CENTER_LATLON = (34.7350, -83.3877)   # middle of the gorge
WIDTH_M = 4000                        # frame width on the ground (height follows aspect)
SIZE_1X = (3024, 1964)                # 14" MacBook Pro native pixels
DEM_RES_M = 1                         # 1 = lidar; 10 for the 1/3 arc-second fallback
SMOOTH_SIGMA_M = 2.0                  # gentle Gaussian; keeps cliff walls tight

INTERVAL_M = 5                        # contour interval
INDEX_EVERY = 5                       # every Nth contour is an index contour

BG = "#0A0F14"
CONTOUR = "#4C566A"
INDEX = "#5E6779"
RIVER = "#8C9F82"
SHOW_RIVER = False                    # NHD flowline overlay (off: the contours carry it)
GLOW = "#8C9F82"

CONTOUR_PX = 0.6                      # line widths at 1x
INDEX_PX = 0.9
RIVER_PX = 1.8
RIVER_GLOW_OPACITY = 0.22
RIVER_GLOW_BLUR_PX = 6

GLOW_CENTER = (0.30, 0.72)            # fraction of width, fraction of height from top
GLOW_RADIUS = 0.75                    # fraction of image height
GLOW_OPACITY = 0.07

TOP_QUIET_PX = 64                     # sketchybar + notch at 1x
TOP_FADE = (0.30, 0.20)               # contour opacity at the top edge, fade length (fraction of height)

# Solar dynamic wallpaper: a faint hillshade under the contours follows the real sun
SURFACE = "#1E222A"                   # lit slopes lift the background toward this, never darker
HILLSHADE_STRENGTH = 0.5              # 0..1 of the way from BG to SURFACE at the brightest slope
HILLSHADE_SIGMA_M = 4.0               # extra smoothing so tree-scale lidar noise doesn't sparkle
HILLSHADE_EXAGGERATION = 1.0          # vertical exaggeration if relief reads flat
SUN_LOCATION = (34.73, -83.39, "America/New_York")   # Tallulah Falls (≈ Atlanta's sky)
SUN_DATES = ("2026-06-21", "2026-03-20", "2026-12-21")
DAY_FRAMES = 16
NIGHT_FRAMES = ((-15.0, 285.0), (-15.0, 75.0))      # after dusk, before dawn: plain contour map
WALLPAPPER_VERSION = ("1.7.4", "5d099a7b09948307ccab4aca046e90ef5456c13cb826498a5a871205adb57afd")

SHOW_COORDS = False
COORDS_TEXT = "34.737° N  83.390° W"
FONT = Path.home() / "Library/Fonts/JetBrainsMonoNerdFont-Regular.ttf"

CACHE = Path.home() / ".cache/rice-topo"
OUT_DIR = Path(__file__).resolve().parent
OUT_NAME = "topo-tallulah"
# -------------------------------------------------------------------------

UTM = 32617  # WGS 84 / UTM zone 17N

# HyRiver's HTTP cache defaults to ./cache in the working directory; keep it out of the repo
CACHE.mkdir(parents=True, exist_ok=True)
os.environ.setdefault("HYRIVER_CACHE_NAME", str(CACHE / "aiohttp_cache.sqlite"))


def hex_rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255


def frame_utm():
    """Frame (xmin, ymin, xmax, ymax) in UTM metres, matching the output aspect."""
    from pyproj import Transformer
    to_utm = Transformer.from_crs(4326, UTM, always_xy=True)
    cx, cy = to_utm.transform(CENTER_LATLON[1], CENTER_LATLON[0])
    w = WIDTH_M
    h = w * SIZE_1X[1] / SIZE_1X[0]
    return cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2


def fetch_bbox(frame, pad=200):
    """Lat/lon box covering the frame plus padding (so edge contours are complete)."""
    from pyproj import Transformer
    to_ll = Transformer.from_crs(UTM, 4326, always_xy=True)
    xmin, ymin, xmax, ymax = frame
    xs, ys = [xmin - pad, xmax + pad], [ymin - pad, ymax + pad]
    lons, lats = zip(*[to_ll.transform(x, y) for x in xs for y in ys])
    return min(lons), min(lats), max(lons), max(lats)


def cache_key(*parts):
    return hashlib.sha1(repr(parts).encode()).hexdigest()[:12]


def load_dem(bbox):
    """3DEP DEM in UTM 17N as (x, y, z); cached as .npz."""
    import py3dep
    path = CACHE / f"dem-{cache_key(bbox, DEM_RES_M)}.npz"
    if path.exists():
        d = np.load(path)
        return d["x"], d["y"], d["z"]
    avail = py3dep.check_3dep_availability(bbox)
    res = DEM_RES_M if avail.get(f"{DEM_RES_M}m") else 10
    print(f"fetching {res} m DEM (availability: {avail})")
    dem = py3dep.get_map("DEM", bbox, resolution=res, geo_crs=4326, crs=UTM)
    x, y, z = dem.x.values, dem.y.values, dem.values.astype(np.float32)
    CACHE.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(path, x=x, y=y, z=z)
    return x, y, z


def load_river(bbox, x, y, z):
    """Tallulah River flowline(s) in UTM as a list of (N, 2) arrays."""
    path = CACHE / f"river-{cache_key(bbox)}.npz"
    if path.exists():
        d = np.load(path)
        return [d[k] for k in sorted(d.files)]
    try:
        import pynhd
        fl = pynhd.WaterData("nhdflowline_network").bybox(bbox)
        fl = fl[fl["gnis_name"].fillna("").str.contains("Tallulah")].to_crs(UTM)
        lines = []
        for geom in fl.geometry:
            parts = getattr(geom, "geoms", [geom])
            lines += [np.asarray(p.coords)[:, :2] for p in parts]
        if not lines:
            raise ValueError("no Tallulah flowlines in box")
    except Exception as e:  # fall back to the DEM's lowest path, column by column
        print(f"NHD unavailable ({e}); deriving channel from the DEM")
        rows = np.nanargmin(z, axis=0)
        lines = [np.column_stack([x, y[rows]])]
    CACHE.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(path, **{f"l{i:03d}": l for i, l in enumerate(lines)})
    return lines


def render_layer(size, frame, draw):
    """Render one transparent matplotlib layer at exactly `size` pixels; return alpha (H, W)."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    dpi = 100
    fig = plt.figure(figsize=(size[0] / dpi, size[1] / dpi), dpi=dpi)
    fig.patch.set_alpha(0)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_axis_off()
    ax.set_xlim(frame[0], frame[2])
    ax.set_ylim(frame[1], frame[3])
    ax.set_aspect("auto")
    draw(ax, 72 / dpi)  # px -> pt factor
    fig.canvas.draw()
    rgba = np.asarray(fig.canvas.buffer_rgba(), dtype=np.float32) / 255
    plt.close(fig)
    return rgba[..., 3]


def build_layers(size, scale, frame, x, y, zs, river, interval):
    """Everything that is identical in every frame: background, glow, contours, fades."""
    from scipy.ndimage import gaussian_filter
    W, H = size
    zmin = np.floor(np.nanmin(zs) / interval) * interval
    levels = np.arange(zmin, np.nanmax(zs) + interval, interval)
    index_levels = levels[np.round(levels / interval).astype(int) % INDEX_EVERY == 0]
    minor_levels = np.setdiff1d(levels, index_levels)

    minor = render_layer(size, frame, lambda ax, pt: ax.contour(
        x, y, zs, levels=minor_levels, colors="w", linewidths=CONTOUR_PX * scale * pt, antialiased=True))
    index = render_layer(size, frame, lambda ax, pt: ax.contour(
        x, y, zs, levels=index_levels, colors="w", linewidths=INDEX_PX * scale * pt, antialiased=True))

    if not river:
        riv = np.zeros((H, W), np.float32)

    def draw_river(ax, pt):
        for line in river:
            ax.plot(line[:, 0], line[:, 1], color="w", linewidth=RIVER_PX * scale * pt,
                    solid_capstyle="round", solid_joinstyle="round", antialiased=True)
    if river:
        riv = render_layer(size, frame, draw_river)

    # background + soft sage atmosphere
    base = np.empty((H, W, 3), np.float32)
    base[:] = hex_rgb(BG)
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    gx, gy = GLOW_CENTER[0] * W, GLOW_CENTER[1] * H
    d = np.hypot(xx - gx, yy - gy) / (GLOW_RADIUS * H)
    g = GLOW_OPACITY * np.clip(1 - d, 0, 1) ** 2
    base += (hex_rgb(GLOW) - base) * g[..., None]

    # contours fade toward the top; extra quiet under the bar
    t = np.clip(yy[:, :1] / (TOP_FADE[1] * H), 0, 1)
    fade = TOP_FADE[0] + (1 - TOP_FADE[0]) * (t * t * (3 - 2 * t))
    fade[: int(TOP_QUIET_PX * scale)] *= 0.6

    return dict(size=size, scale=scale, base=base, minor=minor, index=index, riv=riv,
                fade=fade, river=bool(river))


def render_frame(layers, lift=None):
    """Composite one frame. `lift` (H, W) in 0..1 raises the background toward SURFACE
    under the contours; None gives exactly the static wallpaper."""
    from scipy.ndimage import gaussian_filter
    W, H = layers["size"]
    scale, fade = layers["scale"], layers["fade"]
    img = layers["base"].copy()

    def over(color, alpha):
        nonlocal img
        img += (hex_rgb(color) - img) * alpha[..., None]

    if lift is not None:
        over(SURFACE, lift * fade)
    over(CONTOUR, layers["minor"] * fade)
    over(INDEX, layers["index"] * fade)
    if layers["river"]:
        riv = layers["riv"]
        over(RIVER, np.clip(gaussian_filter(riv, RIVER_GLOW_BLUR_PX * scale) * 2.5, 0, 1) * RIVER_GLOW_OPACITY)
        over(RIVER, riv)

    from PIL import Image, ImageDraw, ImageFont
    out = Image.fromarray((np.clip(img, 0, 1) * 255 + 0.5).astype(np.uint8), "RGB")
    if SHOW_COORDS and FONT.exists():
        draw = ImageDraw.Draw(out)
        font = ImageFont.truetype(str(FONT), int(22 * scale))
        pad = int(56 * scale)
        tw = draw.textlength(COORDS_TEXT, font=font)
        draw.text((W - pad - tw, H - pad - font.size), COORDS_TEXT, font=font, fill=CONTOUR)
    return out


def composite(size, scale, frame, x, y, zs, river, interval):
    return render_frame(build_layers(size, scale, frame, x, y, zs, river, interval))


# ------------------------------------------------------------ solar dynamic
def sun_positions():
    """~DAY_FRAMES well-spread (altitude, azimuth) pairs over the year, plus night frames."""
    from datetime import datetime, timedelta
    from zoneinfo import ZoneInfo
    from astral import Observer
    from astral.sun import azimuth, elevation
    lat, lon, tz = SUN_LOCATION
    obs = Observer(latitude=lat, longitude=lon)
    samples = []
    for day in SUN_DATES:
        start = datetime.fromisoformat(day).replace(tzinfo=ZoneInfo(tz))
        for minutes in range(0, 24 * 60, 30):
            t = start + timedelta(minutes=minutes)
            alt = elevation(obs, t)
            if alt > 0:
                samples.append((alt, azimuth(obs, t)))

    def vec(a):  # unit vector toward the sun (east, north, up)
        alt, az = np.radians(a)
        return np.array([np.sin(az) * np.cos(alt), np.cos(az) * np.cos(alt), np.sin(alt)])

    vecs = np.array([vec(a) for a in samples])
    picked = [int(np.argmax([a for a, _ in samples]))]          # start at the highest sun
    while len(picked) < min(DAY_FRAMES, len(samples)):         # greedy farthest-point thinning
        d = np.min(np.linalg.norm(vecs[:, None] - vecs[picked][None], axis=2), axis=1)
        picked.append(int(np.argmax(d)))
    day = sorted((round(samples[i][0], 2), round(samples[i][1], 2)) for i in picked)
    day.sort(key=lambda p: p[1])                                # morning -> evening
    return list(NIGHT_FRAMES), day


def hillshade_sampler(x, y, z, frame, size):
    """Return f(alt, az) -> lift (H, W) on the output pixel grid."""
    from scipy.ndimage import gaussian_filter, map_coordinates
    res = abs(float(x[1] - x[0]))
    zh = gaussian_filter(np.where(np.isfinite(z), z, np.nanmean(z)), HILLSHADE_SIGMA_M / res)
    dzdy, dzdx = np.gradient(zh * HILLSHADE_EXAGGERATION, y, x)   # y may be descending; gradient handles it
    norm = np.sqrt(dzdx ** 2 + dzdy ** 2 + 1)
    nx, ny, nz = -dzdx / norm, -dzdy / norm, 1 / norm

    W, H = size
    xmin, ymin, xmax, ymax = frame
    px = xmin + (np.arange(W) + 0.5) / W * (xmax - xmin)
    py = ymax - (np.arange(H) + 0.5) / H * (ymax - ymin)
    cols = (px - x[0]) / (x[1] - x[0])
    rows = (py - y[0]) / (y[1] - y[0])
    rr, cc = np.meshgrid(rows, cols, indexing="ij")
    sample = lambda a: map_coordinates(a, [rr, cc], order=1, mode="nearest").astype(np.float32)
    nx, ny, nz = sample(nx), sample(ny), sample(nz)

    def lift(alt, az):
        a, b = np.radians(alt), np.radians(az)
        sun = (np.sin(b) * np.cos(a), np.cos(b) * np.cos(a), np.sin(a))
        hs = nx * sun[0] + ny * sun[1] + nz * sun[2]               # cos(incidence)
        extra = np.clip(hs - np.sin(a), 0, None)                   # brighter than flat ground only
        p99 = float(np.percentile(extra, 99)) or 1.0
        return np.clip(extra / p99, 0, 1)
    return lift


def ensure_wallpapper():
    """Path to the `wallpapper` CLI; builds the pinned, checksum-verified release if missing."""
    import shutil, subprocess, tarfile, urllib.request
    found = shutil.which("wallpapper")
    if found:
        return found
    binary = CACHE / "bin/wallpapper"
    if binary.exists():
        return str(binary)
    version, sha = WALLPAPPER_VERSION
    build = CACHE / "build"
    build.mkdir(parents=True, exist_ok=True)
    tgz = build / f"wallpapper-{version}.tar.gz"
    print(f"building wallpapper {version} (pinned, sha256-verified)")
    urllib.request.urlretrieve(f"https://github.com/mczachurski/wallpapper/archive/{version}.tar.gz", tgz)
    if hashlib.sha256(tgz.read_bytes()).hexdigest() != sha:
        raise SystemExit("wallpapper download failed checksum verification")
    with tarfile.open(tgz) as t:
        t.extractall(build, filter="data")
    src = build / f"wallpapper-{version}"
    # The Command Line Tools' default SwiftPM build system fails here; the native one works
    subprocess.run(["swift", "build", "--configuration", "release", "--build-system", "native"],
                   cwd=src, check=True)
    binary.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy(src / ".build/release/wallpapper", binary)
    return str(binary)


def build_dynamic(layers, lift_fn, strength, out_heic, preview):
    import json, subprocess, shutil
    frames_dir = CACHE / "dynamic"
    shutil.rmtree(frames_dir, ignore_errors=True)
    frames_dir.mkdir(parents=True)
    night, day = sun_positions()
    entries, thumbs = [], []
    for i, (alt, az) in enumerate(night + day):
        lift = None if alt <= -6 else strength * lift_fn(alt, az)
        img = render_frame(layers, lift)
        name = f"frame-{i:02d}.png"
        img.save(frames_dir / name)
        entry = {"fileName": name, "altitude": alt, "azimuth": az}
        if i == 0:
            entry["isPrimary"] = True
        entries.append(entry)
        thumbs.append((img, alt, az))
        print(f"  frame {i:02d}  alt {alt:7.2f}°  az {az:7.2f}°  {'night' if lift is None else 'hillshade'}")
    (frames_dir / "wallpapper.json").write_text(json.dumps(entries, indent=2))
    subprocess.run([ensure_wallpapper(), "-i", "wallpapper.json", "-o", str(out_heic)],
                   cwd=frames_dir, check=True)
    print(f"wrote {out_heic} ({os.path.getsize(out_heic) // 1024} KB, {len(entries)} frames)")
    if preview:
        sheet = contact_sheet(thumbs)
        sheet_path = Path(str(out_heic)).with_suffix(".preview.png")
        sheet.save(sheet_path)
        print(f"wrote {sheet_path}")


def contact_sheet(thumbs, cols=3, thumb_w=1008):
    """All frames with altitude/azimuth labels, plus a 2x crop strip of the gorge for each."""
    from PIL import Image, ImageDraw, ImageFont
    W, H = thumbs[0][0].size
    th = int(thumb_w * H / W)
    label_h = 44
    rows = -(-len(thumbs) // cols)
    sheet = Image.new("RGB", (cols * thumb_w, rows * (th + label_h)), BG)
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.truetype(str(FONT), 22) if FONT.exists() else ImageFont.load_default()
    for i, (img, alt, az) in enumerate(thumbs):
        x, y = (i % cols) * thumb_w, (i // cols) * (th + label_h)
        sheet.paste(img.resize((thumb_w, th), Image.LANCZOS), (x, y + label_h))
        label = f"{i:02d}  night  (alt {alt:.0f}°)" if alt <= -6 else f"{i:02d}  alt {alt:5.1f}°  az {az:5.1f}°"
        draw.text((x + 14, y + 10), label, font=font, fill=CONTOUR if alt <= -6 else GLOW)
    return sheet


def main():
    global SHOW_COORDS
    ap = argparse.ArgumentParser()
    ap.add_argument("--interval", type=float, default=INTERVAL_M)
    ap.add_argument("--coords", action="store_true", default=SHOW_COORDS)
    ap.add_argument("--river", action="store_true", default=SHOW_RIVER)
    ap.add_argument("--only-1x", action="store_true")
    ap.add_argument("--dynamic", action="store_true", help="build the solar dynamic .heic")
    ap.add_argument("--strength", type=float, default=HILLSHADE_STRENGTH,
                    help="hillshade strength 0..1 (fraction of BG -> SURFACE)")
    ap.add_argument("--preview", action="store_true", help="with --dynamic: write a contact sheet")
    ap.add_argument("--out", default=str(OUT_DIR / OUT_NAME), help="output path without extension")
    args = ap.parse_args()
    SHOW_COORDS = args.coords

    from scipy.ndimage import gaussian_filter
    frame = frame_utm()
    bbox = fetch_bbox(frame)
    x, y, z = load_dem(bbox)
    res = abs(float(x[1] - x[0]))
    zs = gaussian_filter(np.where(np.isfinite(z), z, np.nanmean(z)), SMOOTH_SIGMA_M / res)
    river = load_river(bbox, x, y, z) if args.river else []
    print(f"DEM {z.shape} @ {res:.1f} m, elevation {np.nanmin(z):.0f}–{np.nanmax(z):.0f} m, "
          f"{len(river)} river segments, interval {args.interval:g} m")

    if args.dynamic:
        layers = build_layers(SIZE_1X, 1, frame, x, y, zs, river, args.interval)
        lift_fn = hillshade_sampler(x, y, z, frame, SIZE_1X)
        build_dynamic(layers, lift_fn, args.strength, Path(f"{args.out}-dynamic.heic"), args.preview)
        return

    sizes = [(1, SIZE_1X)] if args.only_1x else [(1, SIZE_1X), (2, (SIZE_1X[0] * 2, SIZE_1X[1] * 2))]
    for scale, size in sizes:
        img = composite(size, scale, frame, x, y, zs, river, args.interval)
        path = f"{args.out}.png" if scale == 1 else f"{args.out}@2x.png"
        img.save(path, optimize=True)
        print(f"wrote {path} ({os.path.getsize(path) // 1024} KB)")


if __name__ == "__main__":
    main()
