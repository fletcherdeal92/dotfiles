#!/usr/bin/env bash
# Deploy severance.css (Severance) to Glance on the home server.
#   ./deploy.sh            copy severance.css into the Glance stack's assets/ folder
#   ./deploy.sh --dry-run  show what would happen
# Glance reads it via `theme.custom-css-file: /assets/severance.css` (assets mounted at /app/assets).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../private/homelab.env"   # HOMELAB_HOST (not committed)
HOST="$HOMELAB_HOST"
ASSETS="${GLANCE_ASSETS_DIR:-docker/glance/assets}"   # relative to the server user's home

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
run() { if [ $DRY = 1 ]; then echo "  would run: $*"; else "$@"; fi; }
say() { printf '\033[38;2;140;159;130m==>\033[0m %s\n' "$*"; }

say "Copying severance.css to $HOST:~/$ASSETS"
run ssh -o BatchMode=yes "$HOST" "mkdir -p ~/$ASSETS"
run scp -q "$HERE/severance.css" "$HOST:$ASSETS/severance.css"

say "Done — hard-reload Glance in the browser (Cmd+Shift+R)"
