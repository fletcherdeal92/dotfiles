#!/usr/bin/env bash

# Focused window: app icon + window title (falls back to the app name).

source "$CONFIG_DIR/helpers/icon_map.sh"

HYPRSPACE_BIN="${HYPRSPACE_BIN:-/opt/homebrew/bin/hyprspace}"

info="$("$HYPRSPACE_BIN" list-windows --focused --format '%{app-name}|%{window-title}' 2>/dev/null)"
app="${info%%|*}"
title="${info#*|}"

if [ -z "$app" ]; then
    sketchybar --set "$NAME" icon.drawing=off label=""
    exit 0
fi

[ -z "$title" ] && title="$app"

# Only touch the label when it changes, so long titles keep scrolling
current="$(sketchybar --query "$NAME" | jq -r '.label.value')"
[ "$title" = "$current" ] && exit 0

__icon_map "$app"

sketchybar --set "$NAME" icon.drawing=on icon="$icon_result" label="$title"
