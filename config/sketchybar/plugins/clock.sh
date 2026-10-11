#!/usr/bin/env bash

# Bar label like "Sat 10/10  10:52 AM"; click shows this month's calendar.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/helpers/hover.sh"
handle_hover

fill_calendar() {
    local today i=0 color line args=()
    today=$(date +%-d)
    while IFS= read -r line; do
        if [ $i -eq 0 ]; then
            color=$SAGE
        elif [ $i -eq 1 ]; then
            color=$MUTED
        elif [[ " $line " == *" $today "* ]]; then
            color=$SAGE
        else
            color=$FG
        fi
        args+=(--set clock.cal.$i drawing=on label="$line" label.color=$color)
        i=$((i + 1))
    done < <(/usr/bin/cal | sed -e 's/[[:space:]]*$//' -e '/^$/d')
    while [ $i -lt 8 ]; do
        args+=(--set clock.cal.$i drawing=off)
        i=$((i + 1))
    done
    sketchybar "${args[@]}"
}

if [ "$SENDER" = "mouse.clicked" ]; then
    fill_calendar
    sketchybar --set battery popup.drawing=off --set volume popup.drawing=off \
        --set "$NAME" popup.drawing=toggle
    exit 0
fi

# e.g. "Sat 10/10  10:52 AM"
sketchybar --set "$NAME" label="$(date '+%a %m/%d  %-I:%M %p')"
