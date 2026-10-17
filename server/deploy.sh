#!/usr/bin/env bash
# Copy server/fastfetch to the home server's ~/.config/fastfetch and run setup.sh there.
#   ./server/deploy.sh [ssh-host]   (default: lin-server)
set -euo pipefail
HOST="${1:-lin-server}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ssh "$HOST" 'mkdir -p ~/.config/fastfetch/bin'
scp -q "$HERE"/fastfetch/{config.jsonc,logo.txt,login.sh} "$HOST":.config/fastfetch/
scp -q "$HERE"/fastfetch/bin/*.sh "$HOST":.config/fastfetch/bin/
ssh "$HOST" 'bash -s' < "$HERE/setup.sh"
