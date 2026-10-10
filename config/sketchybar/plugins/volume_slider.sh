#!/bin/sh

# Dragging the slider sends one mouse.clicked with $PERCENTAGE on release.

if [ "$SENDER" = "mouse.clicked" ] && [ -n "$PERCENTAGE" ]; then
    osascript -e "set volume output volume $PERCENTAGE"
fi
