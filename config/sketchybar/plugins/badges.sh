#!/usr/bin/env bash

# Gold dot on a workspace pill when any app on that workspace has a Dock badge.
# One driver item checks every running app with a window (cheap: one hyprspace
# call + one lsappinfo per app) and only animates dots whose state changed.

source "$CONFIG_DIR/colors.sh"

HYPRSPACE_BIN="${HYPRSPACE_BIN:-/opt/homebrew/bin/hyprspace}"
STATE="${TMPDIR:-/tmp}/sketchybar_badges"

# bash 3.2 (macOS /bin/bash): no associative arrays, so use " a b c " strings
badged=" "
checked=" "
while IFS='|' read -r ws pid; do
    [ -z "$ws" ] || [ -z "$pid" ] && continue
    case "$checked" in
    *" $pid=1 "*) badged+="$ws " ; continue ;;
    *" $pid=0 "*) continue ;;
    esac
    label="$(lsappinfo info -only StatusLabel "$pid" 2>/dev/null | sed -n 's/.*"label"="\([^"]*\)".*/\1/p')"
    if [ -n "$label" ]; then checked+="$pid=1 "; badged+="$ws "; else checked+="$pid=0 "; fi
done < <("$HYPRSPACE_BIN" list-windows --all --format '%{workspace}|%{app-pid}' 2>/dev/null)

args=()
new_state=""
for item in $(sketchybar --query bar | jq -r '.items[] | select(test("^space\\.[^.]+\\.badge$"))'); do
    ws="${item#space.}"; ws="${ws%.badge}"
    on=0; [[ "$badged" == *" $ws "* ]] && on=1
    new_state+="$ws=$on "
    if [[ " $(cat "$STATE" 2>/dev/null) " != *" $ws=$on "* ]]; then
        if [ $on = 1 ]; then color="$GOLD"; else color="$GOLD_OFF"; fi
        args+=(--set "$item" icon.color="$color")
    fi
done
echo "$new_state" > "$STATE"

[ ${#args[@]} -gt 0 ] && sketchybar --animate tanh 15 "${args[@]}"
exit 0
