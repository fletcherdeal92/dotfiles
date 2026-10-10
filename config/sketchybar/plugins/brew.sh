#!/usr/bin/env bash

# Number of outdated Homebrew packages, refreshed hourly (and on click).

source "$CONFIG_DIR/colors.sh"

BREW=/opt/homebrew/bin/brew

# sketchybar starts plugins with SIGCHLD ignored, which breaks brew's
# subprocess handling ("undefined method 'exitstatus' for nil").
# bash can't un-ignore an inherited signal, so reset it via perl.
brew() { /usr/bin/perl -e '$SIG{CHLD} = "DEFAULT"; exec @ARGV' "$BREW" "$@"; }

[ "$SENDER" = "mouse.clicked" ] && sketchybar --set "$NAME" label="…"

brew update --quiet >/dev/null 2>&1
COUNT="$(brew outdated --quiet 2>/dev/null | grep -c .)"

if [ "$COUNT" -gt 0 ]; then
    sketchybar --set "$NAME" icon.color="$GOLD" label="$COUNT" label.drawing=on
else
    sketchybar --set "$NAME" icon.color="$MUTED" label="" label.drawing=off
fi
