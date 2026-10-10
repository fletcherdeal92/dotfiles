#!/bin/sh

# e.g. "Sat 10/10  10:52 AM"
sketchybar --set "$NAME" label="$(date '+%a %m/%d  %-I:%M %p')"
