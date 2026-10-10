#!/usr/bin/env bash

# Focused window: app icon + window title (falls back to the app name).

source "$CONFIG_DIR/helpers/icon_map.sh"

HYPRSPACE_BIN="${HYPRSPACE_BIN:-/opt/homebrew/bin/hyprspace}"
STATE="${TMPDIR:-/tmp}/sketchybar_front_app"
PIDFILE="${TMPDIR:-/tmp}/sketchybar_marquee_$NAME.pid"

stop_marquee() {
    [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null
    rm -f "$PIDFILE"
}

info="$("$HYPRSPACE_BIN" list-windows --focused --format '%{app-name}|%{window-title}' 2>/dev/null)"
app="${info%%|*}"
title="${info#*|}"

if [ -z "$app" ]; then
    stop_marquee
    rm -f "$STATE"
    sketchybar --set "$NAME" icon.drawing=off label=""
    exit 0
fi

[ -z "$title" ] && title="$app"

# Only act when the title changes; long titles get the marquee helper
[ "$title" = "$(cat "$STATE" 2>/dev/null)" ] && exit 0
printf '%s' "$title" > "$STATE"

stop_marquee

__icon_map "$app"
sketchybar --set "$NAME" icon.drawing=on icon="$icon_result" label="${title:0:40}"

if [ "${#title}" -gt 40 ]; then
    nohup /usr/bin/python3 "$CONFIG_DIR/helpers/marquee.py" "$NAME" "$title" >/dev/null 2>&1 &
    echo $! > "$PIDFILE"
fi
