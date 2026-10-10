#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

BATT="$(pmset -g batt)"
PERCENTAGE=$(echo "$BATT" | grep -o '[0-9]\+%' | cut -d% -f1)

if [[ -z "$PERCENTAGE" ]]; then
    exit 0
fi

case ${PERCENTAGE} in
9[0-9] | 100) ICON="" ;;
[6-8][0-9])   ICON="" ;;
[3-5][0-9])   ICON="" ;;
[1-2][0-9])   ICON="" ;;
*)            ICON="" ;;
esac

if [[ $PERCENTAGE -ge 50 ]]; then
    ICON_COLOR="$SAGE"
elif [[ $PERCENTAGE -ge 20 ]]; then
    ICON_COLOR="$GOLD"
else
    ICON_COLOR="$RED"
fi

if echo "$BATT" | grep -q 'AC Power'; then
    ICON=""
    ICON_COLOR="$SAGE"
fi

sketchybar --set "$NAME" \
    icon="$ICON" \
    icon.color="$ICON_COLOR" \
    label="${PERCENTAGE}%"
