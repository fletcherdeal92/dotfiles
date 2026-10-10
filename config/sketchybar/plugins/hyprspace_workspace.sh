#!/usr/bin/env bash

source "$CONFIG_DIR/colors.sh"

if [ -n "${HYPRSPACE_BIN:-}" ]; then
    HYPRSPACE_BIN="$HYPRSPACE_BIN"
elif command -v brew >/dev/null 2>&1; then
    HYPRSPACE_BIN="$(brew --prefix)/bin/hyprspace"
elif [ "$(uname -m)" = "arm64" ]; then
    HYPRSPACE_BIN="/opt/homebrew/bin/hyprspace"
else
    HYPRSPACE_BIN="/usr/local/bin/hyprspace"
fi

if [ ! -x "$HYPRSPACE_BIN" ]; then
    HYPRSPACE_BIN="$(command -v hyprspace 2>/dev/null || true)"
fi

# The hyprspace_workspace_change event can supply FOCUSED_WORKSPACE.
# The item invoking this script is in $NAME.

[ -z "$NAME" ] && exit 0

source "$CONFIG_DIR/helpers/icon_map.sh"

sid="${NAME#space.}"

focused="$FOCUSED_WORKSPACE"
if [ -z "$focused" ]; then
    focused="$("$HYPRSPACE_BIN" list-workspaces --focused 2>/dev/null)"
fi

# App icons for every window on this workspace (one icon per app)
icons=""
while IFS= read -r app; do
    [ -z "$app" ] && continue
    __icon_map "$app"
    icons="$icons $icon_result"
done <<EOF
$("$HYPRSPACE_BIN" list-windows --workspace "$sid" --format '%{app-name}' 2>/dev/null | sort -u)
EOF
icons="${icons# }"

if [ -n "$icons" ]; then
    label=(label="$icons" label.drawing=on icon.padding_right=4)
else
    label=(label.drawing=off icon.padding_right=10)
fi

if [ "$sid" = "$focused" ]; then
    sketchybar --set "$NAME" "${label[@]}" background.drawing=on icon.color="$BG" label.color="$BG"
else
    sketchybar --set "$NAME" "${label[@]}" background.drawing=off icon.color="$MUTED" label.color="$FG"
fi
