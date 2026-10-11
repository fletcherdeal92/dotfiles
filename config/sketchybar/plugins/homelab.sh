#!/usr/bin/env bash

# Homelab status dot over Tailscale: sage = VM up + Homepage 200, gold = VM up
# but Homepage down, red = VM unreachable, muted = Tailscale disconnected.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/helpers/hover.sh"
handle_hover

# Addresses live outside git: <dotfiles>/private/homelab.env
PRIVATE="$(cd "$CONFIG_DIR" && pwd -P)/../../private/homelab.env"
if [ ! -f "$PRIVATE" ]; then
    sketchybar --set "$NAME" icon.color="$MUTED" --set homelab.status label="No private/homelab.env"
    exit 0
fi
source "$PRIVATE"
HOST="$TAILNET_HOST"
URL="$HOMEPAGE_URL"
TAILSCALE="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
STATE="${TMPDIR:-/tmp}/sketchybar_homelab"

case "$SENDER" in
mouse.clicked)
    if [ "$BUTTON" = "right" ]; then
        sketchybar --set "$NAME" popup.drawing=toggle
    else
        open -a Zen "$URL"
    fi
    exit 0
    ;;
esac

state="$("$TAILSCALE" status --json 2>/dev/null | sed -n 's/.*"BackendState": *"\([A-Za-z]*\)".*/\1/p' | head -1)"

if [ "$state" != "Running" ]; then
    color="$MUTED"; status="Tailscale disconnected — check skipped"
elif ! ping -c1 -t1 "$HOST" >/dev/null 2>&1; then
    color="$RED"; status="VM unreachable ($HOST)"
elif [ "$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "$URL")" = "200" ]; then
    color="$SAGE"; status="VM up · Homepage OK"
else
    color="$GOLD"; status="VM up · Homepage not responding"
fi

checked="$(date '+%-I:%M %p')"
[ "$(cat "$STATE" 2>/dev/null)" = "$color" ] && anim=() || anim=(--animate tanh 15)
echo "$color" > "$STATE"

sketchybar "${anim[@]}" --set "$NAME" icon.color="$color" \
    --set homelab.status label="$status" \
    --set homelab.time label="Checked $checked"
