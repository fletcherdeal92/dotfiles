#!/usr/bin/env bash
# Deploy custom.css (Severance) to Homepage on the home server.
#   ./deploy.sh            back up, then copy custom.css and fix settings.yaml
#   ./deploy.sh --dry-run  show what would happen
set -euo pipefail

HOST="192.168.1.66"                 # SSH host (see ~/.ssh/config)
CONFIG_DIR="${HOMEPAGE_CONFIG_DIR:-}"  # leave empty to read it from the container's mounts
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BACKUPS="$HOME/.cache/rice-homepage/backups"
STAMP="$(date +%Y%m%d%H%M%S)"

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
run() { if [ $DRY = 1 ]; then echo "  would run: $*"; else "$@"; fi; }
say() { printf '\033[38;2;140;159;130m==>\033[0m %s\n' "$*"; }

if [ -z "$CONFIG_DIR" ]; then
    say "Finding Homepage's config folder on $HOST"
    CONFIG_DIR="$(ssh -o BatchMode=yes "$HOST" \
        'for c in $(docker ps --format "{{.Names}}" | grep -i homepage); do
             docker inspect -f "{{range .Mounts}}{{if eq .Destination \"/app/config\"}}{{.Source}}{{end}}{{end}}" "$c"
         done' | head -1)"
    [ -n "$CONFIG_DIR" ] || { echo "Could not find a homepage container with /app/config mounted" >&2; exit 1; }
fi
echo "  config: $HOST:$CONFIG_DIR"

say "Backing up custom.css and settings.yaml"
run mkdir -p "$LOCAL_BACKUPS"
for f in custom.css settings.yaml; do
    if ssh -o BatchMode=yes "$HOST" "test -f '$CONFIG_DIR/$f'"; then
        run ssh -o BatchMode=yes "$HOST" "cp -p '$CONFIG_DIR/$f' '$CONFIG_DIR/$f.backup.$STAMP'"
        run scp -q "$HOST:$CONFIG_DIR/$f" "$LOCAL_BACKUPS/$f.$STAMP"
        echo "  backed up $f (server: $f.backup.$STAMP, local: ${LOCAL_BACKUPS/#$HOME/~}/$f.$STAMP)"
    fi
done

say "Copying custom.css"
run scp -q "$HERE/custom.css" "$HOST:$CONFIG_DIR/custom.css"

say "Ensuring settings.yaml uses theme: dark / color: slate"
run ssh -o BatchMode=yes "$HOST" "f='$CONFIG_DIR/settings.yaml'; touch \"\$f\";
    grep -q '^theme:' \"\$f\" && sed -i 's/^theme:.*/theme: dark/' \"\$f\" || echo 'theme: dark' >> \"\$f\";
    grep -q '^color:' \"\$f\" && sed -i 's/^color:.*/color: slate/' \"\$f\" || echo 'color: slate' >> \"\$f\""

say "Done — reload Homepage in the browser (no container restart needed)"
