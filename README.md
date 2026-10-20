# dotfiles: Severance

My macOS setup and the small home server it talks to, themed after *Severance*: muted,
corporate-calm, dark. One palette, one font and one repo to rebuild everything.

![Palette](https://img.shields.io/badge/bg-0A0F14-0A0F14) ![](https://img.shields.io/badge/surface-1E222A-1E222A)
![](https://img.shields.io/badge/text-C5C8C6-C5C8C6) ![](https://img.shields.io/badge/muted-4C566A-4C566A)
![](https://img.shields.io/badge/sage-8C9F82-8C9F82) ![](https://img.shields.io/badge/blue-81A1C1-81A1C1)
![](https://img.shields.io/badge/teal-8FBCBB-8FBCBB) ![](https://img.shields.io/badge/gold-EBCB8B-EBCB8B)
![](https://img.shields.io/badge/red-BF616A-BF616A) ![](https://img.shields.io/badge/purple-B48EAD-B48EAD)

| Role | Hex | Used for |
|---|---|---|
| Background | `#0A0F14` | Every window, page and terminal |
| Surface | `#1E222A` | Cards, panels, the bar's right group |
| Text | `#C5C8C6` | Body text |
| Muted | `#4C566A` | Headings, secondary text, inactive things |
| Sage | `#8C9F82` | The one accent: active, focused, healthy |
| Blue / Teal | `#81A1C1` / `#8FBCBB` | Links, info |
| Gold / Red / Purple | `#EBCB8B` / `#BF616A` / `#B48EAD` | Warning / error / visited |

**Font:** JetBrainsMono Nerd Font everywhere, plus `sketchybar-app-font` for app icons.

---

## Quick start

```bash
git clone https://github.com/fletcherdeal92/dotfiles ~/Developer/repos/dotfiles
cd ~/Developer/repos/dotfiles
./install.sh --dry-run      # see what it would do
./install.sh                # Brewfile + symlinks + services
```

| Flag | Does |
|---|---|
| *(none)* | `brew bundle`, link every config, start JankyBorders and Sketchybar |
| `--dry-run` | Prints every step, changes nothing |
| `--links` | Only (re)creates the symlinks and Zen files; rerun after editing Zen CSS |
| `--dynamic-wallpaper` | Also builds and sets the solar dynamic wallpaper (see [wallpapers](wallpapers/README.md)) |

Existing files are backed up (`*.backup.<timestamp>`) before being replaced.
`install.sh` also copies `private.example/` to `private/` if it doesn't exist yet; fill in your
own addresses there (see [Private values](#private-values)).

## Layout

```
Brewfile            every package, cask, App Store app and VS Code extension
install.sh          bootstrap (see above)
zshrc, gitconfig, starship.toml
config/<app>/       symlinked to ~/.config/<app> (Zen and server-side themes are copied/deployed)
wallpapers/         generated wallpapers + the scripts that make them
server/             things that run on the home server (login screen)
private.example/    template for private/, which is gitignored
```

---

## The Mac

**Machine:** 14" MacBook Pro (M1 Pro, notch), Apple Silicon Homebrew.

### Window management

- **[Hyprspace](https://github.com/PeachlifeAB/hyprspace)** (AeroSpace-based tiling).
  Config: `config/hyprspace/config.toml`; reload with `hyprspace reload-config`.
  4 workspaces, 5 px gaps.
- **[JankyBorders](https://github.com/FelixKratz/JankyBorders):** 4 px rounded borders, sage on
  the focused window (`config/borders/bordersrc`, runs via `brew services`).
- **BetterTouchTool:** three-finger swipe left/right switches workspaces
  (`config/bettertouchtool/hyprspace-swipes.bttpreset`, imported into BTT).

| Keys | Action |
|---|---|
| `alt-1` … `alt-4` | Go to workspace |
| `alt-shift-1` … `alt-shift-4` | Move window to workspace |
| `alt-h/j/k/l` | Focus left/down/up/right |
| `alt-shift-h/j/k/l` | Move window |
| `alt-tab` | Previous window |
| `alt-f` / `alt-cmd-f` | Fullscreen / native fullscreen |
| `alt-minus` / `alt-equal` | Narrower / wider (add `shift` for height) |
| `alt-shift-space` | Toggle floating |
| `alt-shift-slash` / `alt-shift-comma` | Tiles / accordion layout |
| `alt-enter` · `alt-b` · `alt-m` | Ghostty · Safari · Spotify |
| `alt-shift-p` | btop in a new Ghostty window |
| `alt-shift-semicolon` | Service mode |

### Sketchybar

A solid **32 px bar, exactly the notch height**; the macOS menu bar auto-hides behind it.

**Left:** workspace pills with each workspace's app icons. The active pill is sage and slides
on switch, and a gold dot fades in when an app there has a Dock badge. Then the focused app's
icon and window title, which scrolls smoothly when it's longer than 40 characters.

**Right** (one rounded surface group, hover highlights on anything clickable):

| Item | Shows | Click |
|---|---|---|
| Clock | `Mon 10/20  9:47 AM` | Month calendar |
| Battery | Charge, coloured by level | State, time left, health and cycles |
| Volume | Level, grey when muted | Slider + output picker; right-click mutes |
| Homelab | Sage = server and dashboard up · gold = dashboard down · red = unreachable · dim = Tailscale off | Opens the dashboard |
| Weather | wttr.in, °F, every 15 min | — |
| Homebrew | Outdated package count, hourly | Refresh |
| What's Up Docker | Containers with image updates | `current → available` list |

Notes for editing: plugins run under macOS's `/bin/bash` 3.2 (no associative arrays) and don't
inherit variables from `sketchybarrc`, so each one sources `colors.sh`. Custom app icons go in
`helpers/icon_overrides.sh`.

### Terminal and shell

- **Ghostty** with a `severance` theme (`config/ghostty/themes/severance`).
- **zsh** + **Starship** prompt, with fzf, zoxide, autosuggestions and syntax highlighting.
- Themed CLI tools: `bat`, `eza`, `btop`, `fzf`, `delta` (git diffs), `lazygit`, `fastfetch`.

### Apps

| App | Theme | Where |
|---|---|---|
| Zen browser | `userChrome.css` + `userContent.css` (also styles SearXNG results); start page = Glance | `config/zen/` |
| VS Code | Severance colour theme extension | `config/vscode/` (`install-theme.py` builds the VSIX) |
| Raycast | Theme deeplink | `config/raycast/` |
| Obsidian | CSS snippet | `config/obsidian/` |

Zen ignores `userContent.css` when it's a symlink, so `install.sh` **copies** `config/zen/chrome/*.css`
into the active profile and generates its `user.js` (repo prefs + the private start page URL).
After editing, run `./install.sh --links` and restart Zen.

### Wallpaper

A topographic contour map of **Tallulah Gorge**, generated from USGS 3DEP 1 m lidar by
`wallpapers/topo_tallulah.py`. The **solar dynamic** version follows the real sun over the gorge:
a faint hillshade lifts the sunlit slopes through the day and fades at night. Large outputs are
rebuilt, not committed. Details: [wallpapers/README.md](wallpapers/README.md).

---

## The home server

An Ubuntu VM (ARM64, 4 vCPU, ~4 GB RAM) on a Mac mini, reachable from anywhere over
**Tailscale** (MagicDNS). Docker stacks live in `~/docker/<stack>/`, managed with **Dockge**, and
that folder is a local git repo holding compose files and small configs only. Secrets stay in
each stack's `.env`, and data stays in volumes.

| Service | Job |
|---|---|
| **Homepage** | Container status board, themed by `config/homepage/custom.css` |
| **Glance** | Morning start page: Miniflux unread tabs, YouTube, SearXNG search, weather, releases, service monitor |
| **Miniflux** + Postgres | The reading room: feeds and read state, synced to ReadKit on iPhone and Mac |
| **changedetection.io** | Watches pages without feeds and publishes changes as RSS into Miniflux |
| **SearXNG** + Valkey | Private metasearch (images tab included), themed through Zen |
| **What's Up Docker** | Notify-only image update checks, shown on the bar and Homepage |
| **Tailscale** | Same hostnames at home and away; nothing is on the public internet |

### Reading stack

Feeds live in **Miniflux**, grouped into categories (Tech accountability, News, Atlanta, Georgia,
Appalachia and the South, History, Research, Videos, Releases, Homelab). Everything else is a view
of it:

- **Glance's headline tabs** are Miniflux *unread* lists per category. Click a headline to open
  it in Miniflux, which marks it read, and it clears everywhere, ReadKit included.
- **Research** collects Digital Library of Georgia search feeds and changedetection.io watches.
- **Blocking rules** (`config/miniflux/block-rules.txt`) hide sports across every feed, by tag
  and by team or league in the title.

### Theming the server apps from here

| App | Source | Deploy |
|---|---|---|
| Homepage | `config/homepage/custom.css` | `config/homepage/deploy.sh` (backs up first) |
| Glance | `config/glance/severance.css` | `config/glance/deploy.sh` → the stack's `assets/` |
| Miniflux | `config/miniflux/severance.css` + `block-rules.txt` | `config/miniflux/deploy.sh` → Custom CSS + blocking rules via the API (backs up first) |

Each script takes `--dry-run`.

### Login screen

`server/` holds a **fastfetch** login summary for SSH sessions. Its logo is the *Petrichor* plate:
a small sage Blue Ridge silhouette, `P E T R I C H O R`, `34.73°N 83.39°W`, *after the rain*.
Next to it are OS, uptime, memory, disk, the media share, running containers, pending image
updates and Tailscale state.

```bash
./server/deploy.sh          # copy configs to the server and install fastfetch (no sudo)
uv run server/fastfetch/make_plate.py --preview   # regenerate the logo
```

It only runs for interactive SSH logins (not tmux or scripts) and takes about 80 ms.

---

## Private values

Anything that identifies my network (server address, tailnet name, dashboard URLs, API keys)
lives in **`private/homelab.env`**, which is gitignored. `private.example/homelab.env` is the
template. Sketchybar, `install.sh` and the deploy scripts read from it, so nothing private is
hardcoded in tracked files.

## House rules

These preferences shaped this setup, and new additions should respect them:

- **Smooth, native animations.** Nothing that steps or jitters.
- **US formats:** MM/DD dates, 12-hour time.
- **Keep the bar's right side short;** anything wider disappears under the notch.
- **No CPU/RAM/disk widgets** on the Mac, and **no extra window managers** fighting Hyprspace.
- **Few background processes.** Prefer events to polling; every daemon earns its place.
- **The server has ~4 GB of RAM.** Keep images lean, and keep secrets out of git.
- **No algorithm deciding what comes next.** Feeds I chose, read state I own.
