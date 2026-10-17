# Wallpapers

All generated from code, in the Severance palette. Large outputs are rebuilt, not committed.

| File | What | In git |
|---|---|---|
| `topo_tallulah.py` | Tallulah Gorge contour map from USGS 3DEP 1 m lidar | ✓ |
| `topo-tallulah.png`, `@2x` | Static wallpaper (3024×1964, 6048×3928) | ✓ |
| `topo-tallulah-dynamic.heic` | **Solar dynamic** wallpaper, ~45 MB | ✗ (gitignored) |
| `generate-glow.py` → `severance-glow.png` | The original soft-glow gradient | ✓ |

## Regenerate

```bash
uv run wallpapers/topo_tallulah.py                       # static PNGs
uv run wallpapers/topo_tallulah.py --dynamic             # solar dynamic .heic
uv run wallpapers/topo_tallulah.py --dynamic --preview   # + contact sheet of every frame
uv run wallpapers/topo_tallulah.py --dynamic --strength 0.35   # quieter hillshade (default 0.5)
```

`./install.sh --dynamic-wallpaper` does the `--dynamic` build and sets it. The first run downloads
the lidar (cached in `~/.cache/rice-topo`) and builds the pinned `wallpapper` CLI there too. Output
is byte-for-byte reproducible.

### How the dynamic wallpaper works

Every frame is the same dark contour map. Underneath the contours, a faint hillshade, computed from
the same elevation data, lifts sunlit slopes from `#0A0F14` toward `#1E222A`. It never goes darker
than the background. There are 16 day frames, sampled from real sun positions over Tallulah Falls on the
summer solstice, March equinox and winter solstice. Two night frames (sun below −6°) are pixel-identical
to the static wallpaper. macOS reads the altitude/azimuth stored in the `.heic` and shows the frame
nearest to where the sun actually is.

## Set it as a dynamic wallpaper

1. Build it (see above).
2. **System Settings → Wallpaper → Add Photo…** (or **Add Folder…** and pick `wallpapers/`), then
   choose `topo-tallulah-dynamic.heic`.
3. If macOS offers a choice for this wallpaper, pick **Dynamic** (not Light/Dark).
   Right-clicking the `.heic` in Finder → **Set Desktop Picture** works too.

Location Services lets macOS use your exact location for the sun. Without it, macOS falls back to
your time zone, which is fine for Atlanta.
