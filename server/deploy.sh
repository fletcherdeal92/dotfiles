#!/usr/bin/env bash
# Copy server/fastfetch to the home server's ~/.config/fastfetch and run setup.sh there;
# install server/bin/* (wud-classify, used by the Sketchybar whale) into ~/.local/bin.
#   ./server/deploy.sh [ssh-host]   (default: lin-server)
set -euo pipefail
HOST="${1:-lin-server}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ssh "$HOST" 'mkdir -p ~/.config/fastfetch/bin'
scp -q "$HERE"/fastfetch/{config.jsonc,logo.txt,login.sh} "$HOST":.config/fastfetch/
scp -q "$HERE"/fastfetch/bin/*.sh "$HOST":.config/fastfetch/bin/
ssh "$HOST" 'mkdir -p ~/.local/bin'
scp -q "$HERE"/bin/* "$HOST":.local/bin/
ssh "$HOST" 'chmod +x ~/.local/bin/wud-classify'
ssh "$HOST" 'bash -s' < "$HERE/setup.sh"
