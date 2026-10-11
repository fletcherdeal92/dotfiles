#!/usr/bin/env bash

# Left click: slider + output picker popup. Right click: toggle mute.
# The volume_change event supplies the new volume in $INFO.

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/helpers/hover.sh"
handle_hover

SAS=/opt/homebrew/bin/SwitchAudioSource

fill_devices() {
    local current dev i=0 args=(--remove '/volume\.device\..*/')
    current="$("$SAS" -c -t output)"
    while IFS= read -r dev; do
        [ -z "$dev" ] && continue
        if [ "$dev" = "$current" ]; then
            icon=""; color=$SAGE
        else
            icon="󰓃"; color=$FG
        fi
        case "$dev" in *[Aa]ir[Pp]ods* | *[Hh]eadphone* | *[Bb]eats*) [ "$dev" != "$current" ] && icon="" ;; esac
        args+=(--add item volume.device.$i popup.volume
               --set volume.device.$i icon="$icon" icon.color=$color label="$dev" label.color=$color
                   icon.padding_left=12 icon.padding_right=8 label.padding_right=12
                   click_script="$SAS -t output -s \"$dev\" >/dev/null; sketchybar --set volume popup.drawing=off")
        i=$((i + 1))
    done < <("$SAS" -a -t output)
    sketchybar "${args[@]}"
}

case "$SENDER" in
mouse.clicked)
    if [ "$BUTTON" = "right" ]; then
        osascript -e 'set volume output muted not (output muted of (get volume settings))'
    else
        fill_devices
        sketchybar --set clock popup.drawing=off --set battery popup.drawing=off \
            --set "$NAME" popup.drawing=toggle
    fi
    exit 0
    ;;
volume_change) VOLUME="$INFO" ;;
*) VOLUME="$(osascript -e 'output volume of (get volume settings)')" ;;
esac

SLIDER="$VOLUME"
if [ "$(osascript -e 'output muted of (get volume settings)')" = "true" ]; then
  VOLUME=0
fi

case "$VOLUME" in
  [6-9][0-9]|100) ICON="󰕾" ;;
  [3-5][0-9]) ICON="󰖀" ;;
  [1-9]|[1-2][0-9]) ICON="󰕿" ;;
  *) ICON="󰖁" ;;
esac

if [ "$VOLUME" = "0" ]; then COLOR="$MUTED"; else COLOR="$SAGE"; fi

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$VOLUME%" \
    --set volume.slider slider.percentage="$SLIDER"
