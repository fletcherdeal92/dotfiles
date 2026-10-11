#!/usr/bin/env bash

# Hover highlight for clickable bar items. Call `handle_hover` near the top of
# a plugin; it handles mouse.entered / mouse.exited and exits.

handle_hover() {
    case "$SENDER" in
    mouse.entered)
        sketchybar --animate tanh 8 --set "$NAME" background.color="$HOVER"
        exit 0
        ;;
    mouse.exited)
        sketchybar --animate tanh 8 --set "$NAME" background.color="$HOVER_OFF"
        exit 0
        ;;
    esac
}
