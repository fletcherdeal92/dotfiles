#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

fill_popup() {
    local line state time cycles nominal design health
    line="$(pmset -g batt | sed -n 2p)"
    state="$(printf '%s' "$line" | awk -F'; ' '{print $2}')"
    time="$(printf '%s' "$line" | awk -F'; ' '{print $3}' | awk '{print $1}')"

    case "$state" in
    charging)    state="Charging";              sicon="" ;;
    discharging) state="On battery";            sicon="" ;;
    charged)     state="Fully charged";         sicon="" ;;
    *)           state="Plugged in, not charging"; sicon="" ;;
    esac

    if [[ "$time" =~ ^[0-9]+:[0-9]+$ ]] && [ "$time" != "0:00" ]; then
        h="${time%%:*}"; m="${time#*:}"
        if [ "$state" = "Charging" ]; then
            time="${h}h ${m}m until full"
        else
            time="${h}h ${m}m remaining"
        fi
    elif [ "$state" = "Fully charged" ]; then
        time="—"
    else
        time="Calculating…"
    fi

    data="$(ioreg -rn AppleSmartBattery)"
    cycles="$(printf '%s' "$data" | awk '/"CycleCount" =/ {print $NF; exit}')"
    nominal="$(printf '%s' "$data" | grep -o '"NominalChargeCapacity"=[0-9]*' | head -1 | cut -d= -f2)"
    design="$(printf '%s' "$data" | grep -o '"DesignCapacity"=[0-9]*' | head -1 | cut -d= -f2)"
    if [ -n "$nominal" ] && [ -n "$design" ] && [ "$design" -gt 0 ]; then
        health="$((nominal * 100 / design))% health · ${cycles} cycles"
    else
        health="${cycles} cycles"
    fi

    sketchybar --set battery.status icon="$sicon" label="$state" \
        --set battery.time icon="" label="$time" \
        --set battery.health icon="" label="$health"
}

if [ "$SENDER" = "mouse.clicked" ]; then
    fill_popup
    sketchybar --set clock popup.drawing=off --set volume popup.drawing=off \
        --set "$NAME" popup.drawing=toggle
    exit 0
fi

BATT="$(pmset -g batt)"
PERCENTAGE=$(echo "$BATT" | grep -o '[0-9]\+%' | cut -d% -f1)

if [[ -z "$PERCENTAGE" ]]; then
    exit 0
fi

case ${PERCENTAGE} in
9[0-9] | 100) ICON="" ;;
[6-8][0-9])   ICON="" ;;
[3-5][0-9])   ICON="" ;;
[1-2][0-9])   ICON="" ;;
*)            ICON="" ;;
esac

if [[ $PERCENTAGE -ge 50 ]]; then
    ICON_COLOR="$SAGE"
elif [[ $PERCENTAGE -ge 20 ]]; then
    ICON_COLOR="$GOLD"
else
    ICON_COLOR="$RED"
fi

if echo "$BATT" | grep -q 'AC Power'; then
    ICON=""
    ICON_COLOR="$SAGE"
fi

sketchybar --set "$NAME" \
    icon="$ICON" \
    icon.color="$ICON_COLOR" \
    label="${PERCENTAGE}%"
