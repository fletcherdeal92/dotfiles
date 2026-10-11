#!/usr/bin/env bash
# Bootstrap this Mac rice from the dotfiles repo.
#   ./install.sh            install packages, link configs, start services
#   ./install.sh --dry-run  show what would happen, change nothing
#   ./install.sh --links    only (re)create symlinks
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0; LINKS_ONLY=0
for arg in "$@"; do
    case "$arg" in
    --dry-run) DRY=1 ;;
    --links) LINKS_ONLY=1 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
    esac
done

run() { if [ $DRY = 1 ]; then echo "  would run: $*"; else "$@"; fi; }
say() { printf '\033[38;2;140;159;130m==>\033[0m %s\n' "$*"; }

# target (in $HOME)            -> source (in repo)
LINKS=(
    ".zshrc"                     "zshrc"
    ".gitconfig"                 "gitconfig"
    ".config/starship.toml"      "starship.toml"
    ".config/ghostty"            "config/ghostty"
    ".config/sketchybar"         "config/sketchybar"
    ".config/hyprspace"          "config/hyprspace"
    ".config/borders"            "config/borders"
    ".config/bat"                "config/bat"
    ".config/eza"                "config/eza"
    ".config/btop"               "config/btop"
    ".config/fastfetch"          "config/fastfetch"
    ".config/lazygit"            "config/lazygit"
)

link_all() {
    say "Linking configs"
    run mkdir -p "$HOME/.config"
    local i target source
    for ((i = 0; i < ${#LINKS[@]}; i += 2)); do
        target="$HOME/${LINKS[i]}"; source="$DOTFILES/${LINKS[i + 1]}"
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
            echo "  ok      ~/${LINKS[i]}"
            continue
        fi
        if [ -e "$target" ] || [ -L "$target" ]; then
            local backup="$target.backup.$(date +%Y%m%d%H%M%S)"
            echo "  backup  ~/${LINKS[i]} -> ${backup/#$HOME/~}"
            run mv "$target" "$backup"
        fi
        echo "  link    ~/${LINKS[i]} -> ${LINKS[i + 1]}"
        run ln -s "$source" "$target"
    done
}

if [ $LINKS_ONLY = 1 ]; then link_all; exit 0; fi

if ! command -v brew >/dev/null 2>&1; then
    say "Homebrew is not installed — install it from https://brew.sh first"
    exit 1
fi

say "Installing packages from Brewfile"
run brew bundle --file="$DOTFILES/Brewfile"

link_all

say "Starting services"
run brew services start sketchybar
run brew services start borders

say "Installing VS Code Severance theme"
run python3 "$DOTFILES/config/vscode/install-theme.py"

say "Setting wallpaper"
run osascript -e "tell application \"System Events\" to set picture of every desktop to POSIX file \"$DOTFILES/wallpapers/severance-glow.png\""

say "Done. Manual steps:"
cat <<'STEPS'
  1. Open Hyprspace and grant Accessibility (System Settings → Privacy & Security).
  2. System Settings → Control Center → Automatically hide and show the menu bar: Always.
  3. System Settings → Trackpad → More Gestures → Swipe between full-screen apps: Four Fingers.
  4. BetterTouchTool (Setapp) → Presets → Import config/bettertouchtool/hyprspace-swipes.bttpreset
STEPS
