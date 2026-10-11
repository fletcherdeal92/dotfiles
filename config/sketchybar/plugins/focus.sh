#!/usr/bin/env bash

# Moon while any Focus mode is on. Driven by two Shortcuts automations that run
# `sketchybar --trigger focus_on` / `focus_off`; the last state is kept in a file
# so a reload restores it (reading macOS's own Focus DB needs Full Disk Access).

source "$CONFIG_DIR/colors.sh"

STATE="${TMPDIR:-/tmp}/sketchybar_focus"

case "$SENDER" in
focus_on) echo on > "$STATE" ;;
focus_off) echo off > "$STATE" ;;
esac

if [ "$(cat "$STATE" 2>/dev/null)" = "on" ]; then
    sketchybar --set "$NAME" drawing=on \
        --animate tanh 15 --set "$NAME" icon.color="$MOON"
else
    sketchybar --animate tanh 15 --set "$NAME" icon.color="$MOON_OFF"
    sleep 0.3
    sketchybar --set "$NAME" drawing=off
fi
