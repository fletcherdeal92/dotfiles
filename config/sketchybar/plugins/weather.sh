#!/usr/bin/env bash

# Current conditions from wttr.in (location from IP, Fahrenheit).
# On failure keep the last value rather than blanking the item.

source "$CONFIG_DIR/colors.sh"

RAW="$(curl -fs --max-time 8 'https://wttr.in/?format=%C|%t&u')" || exit 0
case "$RAW" in *"|"*) ;; *) exit 0 ;; esac

COND="$(printf '%s' "${RAW%%|*}" | tr '[:upper:]' '[:lower:]')"
TEMP="${RAW#*|}"
TEMP="${TEMP#+}"

HOUR=$(date +%H)
NIGHT=0
if [ "$HOUR" -ge 19 ] || [ "$HOUR" -lt 6 ]; then NIGHT=1; fi

case "$COND" in
*thunder*) ICON="" ;;
*snow* | *sleet* | *ice* | *blizzard*) ICON="" ;;
*rain* | *drizzle* | *shower*) ICON="" ;;
*fog* | *mist* | *haze*) ICON="" ;;
*partly*) [ $NIGHT = 1 ] && ICON="" || ICON="" ;;
*cloud* | *overcast*) ICON="" ;;
*) [ $NIGHT = 1 ] && ICON="" || ICON="" ;;
esac

sketchybar --set "$NAME" icon="$ICON" icon.color="$GOLD" label="$TEMP"
