#!/usr/bin/env bash
# Deploy severance.css (Severance) to Miniflux as the user's Custom CSS, with the dark serif theme.
#   ./deploy.sh            push severance.css via the Miniflux API
#   ./deploy.sh --dry-run  show what would happen
# Miniflux keeps custom CSS per user in its database (Settings → Custom CSS); this overwrites it.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HERE/../../private/homelab.env"   # MINIFLUX_URL, MINIFLUX_API_KEY (not committed)
THEME="${MINIFLUX_THEME:-dark_serif}"

DRY=0; [ "${1:-}" = "--dry-run" ] && DRY=1
say() { printf '\033[38;2;140;159;130m==>\033[0m %s\n' "$*"; }
api() { curl -fsS -H "X-Auth-Token: $MINIFLUX_API_KEY" -H "Content-Type: application/json" "$@"; }

say "Looking up the Miniflux user"
ME="$(api "$MINIFLUX_URL/v1/me")"
ID="$(jq -r .id <<<"$ME")"
echo "  user: $(jq -r .username <<<"$ME") (id $ID), current theme: $(jq -r .theme <<<"$ME")"

BACKUP="$HOME/.cache/rice-miniflux/stylesheet.$(date +%Y%m%d%H%M%S).css"
say "Backing up the current Custom CSS to ${BACKUP/#$HOME/~}"
if [ $DRY = 0 ]; then mkdir -p "$(dirname "$BACKUP")"; jq -r .stylesheet <<<"$ME" > "$BACKUP"; fi

say "Setting theme $THEME and Custom CSS from severance.css"
BODY="$(jq -n --rawfile css "$HERE/severance.css" --arg theme "$THEME" '{theme: $theme, stylesheet: $css}')"
if [ $DRY = 1 ]; then echo "  would PUT $MINIFLUX_URL/v1/users/$ID ($(wc -c < "$HERE/severance.css" | tr -d ' ') bytes of CSS)"
else api -X PUT -d "$BODY" "$MINIFLUX_URL/v1/users/$ID" | jq -r '"  saved: theme \(.theme), \(.stylesheet | length) bytes of CSS"'; fi

say "Done — reload Miniflux in the browser"
