#!/bin/sh

source "$CONFIG_DIR/colors.sh"

# The volume_change event supplies a $INFO variable in which the current volume
# percentage is passed to the script. On first load, read it directly.

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"
else
  VOLUME="$(osascript -e 'output volume of (get volume settings)')"
fi

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

sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$VOLUME%"
