#!/usr/bin/env bash

# Homelab status dot: sage = VM up + Homepage 200, gold = VM up but Homepage
# down, red = VM unreachable, muted = away from home (check skipped).
# Home is recognised by the DHCP router + domain: Wi-Fi SSIDs and the ARP table
# are hidden from background services, so the router's MAC isn't an option.
# (Another network with the same AT&T defaults would show red, not muted.)

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
HOST="$HOMELAB_HOST"
URL="$HOMEPAGE_URL"
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

iface="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')"
lease="$(ipconfig getpacket "$iface" 2>/dev/null)"
router="$(printf '%s\n' "$lease" | sed -n 's/^router (ip_mult): {\([^,}]*\).*/\1/p')"
domain="$(printf '%s\n' "$lease" | sed -n 's/^domain_name (string): //p')"

if [ "$router" != "$HOME_ROUTER" ] || [ "$domain" != "$HOME_DOMAIN" ]; then
    color="$MUTED"; status="Away from home — check skipped"
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
