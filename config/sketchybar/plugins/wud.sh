#!/usr/bin/env bash

# Containers with an available image update, from What's Up Docker on the home
# server (over Tailscale). Styled like brew.sh: gold count, dim icon at zero.
# Left click: popup listing each container with current -> available.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/helpers/hover.sh"
handle_hover

PRIVATE="$(cd "$CONFIG_DIR" && pwd -P)/../../private/homelab.env"
[ -f "$PRIVATE" ] && source "$PRIVATE"
[ -z "$WUD_URL" ] && exit 0

fetch() {
    curl -s --max-time 5 -u "$WUD_USER:$WUD_PASSWORD" "$WUD_URL/api/containers"
}

# "name<TAB>current<TAB>available" for each container with an update
updates() {
    jq -r '.[] | select(.updateAvailable)
        | [ .name,
            .image.tag.value,
            (if .updateKind.kind == "digest"
               then "new build " + ((.result.created // "")[5:10] | sub("-"; "/"))
               else .result.tag end) ] | @tsv' 2>/dev/null
}

fill_popup() {
    local i=0 args=(--remove '/wud\.row\..*/')
    while IFS=$'\t' read -r name current available; do
        args+=(--add item wud.row.$i popup.wud
               --set wud.row.$i icon="$name" icon.color=$FG icon.width=150
                   icon.padding_left=12 icon.padding_right=8
                   label="$current  →  $available" label.color=$MUTED label.padding_right=12)
        i=$((i + 1))
    done
    if [ $i -eq 0 ]; then
        args+=(--add item wud.row.0 popup.wud
               --set wud.row.0 icon.drawing=off label="All containers up to date"
                   label.color=$MUTED label.padding_left=12 label.padding_right=12)
    fi
    sketchybar "${args[@]}" >/dev/null 2>&1
}

if [ "$SENDER" = "mouse.clicked" ]; then
    fetch | updates | fill_popup
    sketchybar --set clock popup.drawing=off --set battery popup.drawing=off \
        --set volume popup.drawing=off --set homelab popup.drawing=off \
        --set "$NAME" popup.drawing=toggle
    exit 0
fi

JSON="$(fetch)"
[ -z "$JSON" ] && exit 0   # server unreachable: keep the last value
COUNT="$(printf '%s' "$JSON" | updates | grep -c .)"

if [ "$COUNT" -gt 0 ]; then
    sketchybar --set "$NAME" icon.color="$GOLD" label="$COUNT" label.drawing=on
else
    sketchybar --set "$NAME" icon.color="$MUTED" label="" label.drawing=off
fi
