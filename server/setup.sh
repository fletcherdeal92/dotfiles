#!/usr/bin/env bash
# Runs ON the server (deploy.sh calls it). Installs fastfetch into ~/.local from the
# official .deb (no sudo, nothing outside $HOME) and hooks it into ~/.profile.
set -euo pipefail
VERSION="2.70.0"
SHA256="25053651486d97b8731dd6bc59e725944e39adcdcd903741334c1c3282a7281d"
ARCH="$(uname -m)"; [ "$ARCH" = "aarch64" ] || { echo "expected aarch64, got $ARCH" >&2; exit 1; }
OPT="$HOME/.local/opt/fastfetch-$VERSION"

if [ ! -x "$OPT/usr/bin/fastfetch" ]; then
    tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
    curl -fsSL -o "$tmp/ff.deb" "https://github.com/fastfetch-cli/fastfetch/releases/download/$VERSION/fastfetch-linux-aarch64.deb"
    echo "$SHA256  $tmp/ff.deb" | sha256sum -c - >/dev/null
    mkdir -p "$OPT" && dpkg-deb -x "$tmp/ff.deb" "$OPT"
    echo "installed fastfetch $VERSION -> ${OPT/#$HOME/~}"
fi
mkdir -p "$HOME/.local/bin"
ln -sfn "$OPT/usr/bin/fastfetch" "$HOME/.local/bin/fastfetch"
chmod +x "$HOME/.config/fastfetch/bin/"*.sh

HOOK='[ -f "$HOME/.config/fastfetch/login.sh" ] && . "$HOME/.config/fastfetch/login.sh"'
grep -qF "$HOOK" "$HOME/.profile" || printf '\n# fastfetch on SSH login (dotfiles/server)\n%s\n' "$HOOK" >> "$HOME/.profile"
echo "fastfetch $("$HOME/.local/bin/fastfetch" --version | awk '{print $2}') ready; login hook in ~/.profile"
