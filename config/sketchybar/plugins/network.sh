#!/usr/bin/env bash

# Pushes download/upload rates to the network.down / network.up graphs
# (log scale, 50 MB/s = full height) and shows the current rates.

IFACE="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')"
STATE="${TMPDIR:-/tmp}/sketchybar_network"

if [ -z "$IFACE" ]; then
    sketchybar --set "$NAME" label="offline" --push network.down 0 --push network.up 0
    exit 0
fi

read -r IN OUT < <(netstat -ibn -I "$IFACE" | awk 'NR==2 {print $7, $10}')
NOW=$(date +%s)

if [ -f "$STATE" ]; then
    read -r PIFACE PIN POUT PNOW < "$STATE"
fi
echo "$IFACE $IN $OUT $NOW" > "$STATE"

[ "$PIFACE" != "$IFACE" ] || [ -z "$PNOW" ] && exit 0
DT=$((NOW - PNOW)); [ "$DT" -le 0 ] && exit 0

awk -v i="$IN" -v pi="$PIN" -v o="$OUT" -v po="$POUT" -v dt="$DT" '
function human(b) {
    if (b >= 1048576) return sprintf("%.1fM", b / 1048576)
    if (b >= 1024)    return sprintf("%.0fK", b / 1024)
    return sprintf("%.0fB", b)
}
function scale(b) { v = log(1 + b) / log(1 + 50 * 1048576); return v > 1 ? 1 : v }
BEGIN {
    d = (i - pi) / dt; u = (o - po) / dt
    if (d < 0) d = 0; if (u < 0) u = 0
    printf "%.3f %.3f ↓%s ↑%s\n", scale(d), scale(u), human(d), human(u)
}' | {
    read -r DS US LABEL
    sketchybar --push network.down "$DS" --push network.up "$US" --set "$NAME" label="$LABEL"
}
