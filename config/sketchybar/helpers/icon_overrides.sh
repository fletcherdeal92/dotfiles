#!/usr/bin/env bash

# Local icon overrides on top of the vendored icon_map.sh (sketchybar-app-font).
# Glyphs the app font lacks (e.g. Nerd Font ones) fall back to an installed
# Nerd Font automatically, so they work inside app-font labels too.

source "$CONFIG_DIR/helpers/icon_map.sh"

app_icon() {
    case "$1" in
    NEO) icon_result="󱙷" ;; # md-snail
    *) __icon_map "$1" ;;
    esac
}
