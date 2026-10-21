#!/usr/bin/env bash

# Docker image updates worth acting on, from What's Up Docker on the home server.
# WUD's list is piped through server/bin/wud-classify (over ssh), which keeps real
# version changes and drops rebuilds of the same version.
#   0 updates                  -> hidden
#   all newer than STALE_DAYS  -> muted whale + count
#   any waiting STALE_DAYS+    -> gold
# Left click: popup listing each update (current -> available, days waiting).
# `dup` triggers wud_refresh after updating, so the whale clears right away.

STALE_DAYS="${WUD_STALE_DAYS:-3}"

source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/helpers/hover.sh"
handle_hover

PRIVATE="$(cd "$CONFIG_DIR" && pwd -P)/../../private/homelab.env"
[ -f "$PRIVATE" ] && source "$PRIVATE"
[ -z "$WUD_URL" ] && exit 0

STATE="$HOME/.cache/sketchybar"
ROWS="$STATE/wud-rows.tsv"     # last classification: name counted from to since
SEEN="$STATE/wud-seen.tsv"     # first time each (name, version) was seen: name to epoch
mkdir -p "$STATE"; touch "$SEEN" "$ROWS"

fill_popup() {
    local i=0 hidden args=(--remove '/wud\.row\..*/')
    while IFS=$'\t' read -r name from to days; do
        args+=(--add item wud.row.$i popup.wud
               --set wud.row.$i icon="$name" icon.color=$FG icon.width=150
                   icon.padding_left=12 icon.padding_right=8
                   label="$from  →  $to  ·  ${days}d" label.color=$MUTED label.padding_right=12)
        i=$((i + 1))
    done < <(awk -F'\t' -v now="$(date +%s)" 'FILENAME == ARGV[1] { seen[$1 "\t" $2] = $3; next }
        $2 == 1 { t = seen[$1 "\t" $4]; printf "%s\t%s\t%s\t%d\n", $1, $3, $4, (t ? (now - t) / 86400 : 0) }' \
        "$SEEN" "$ROWS" 2>/dev/null)

    hidden="$(awk -F'\t' '$2 == 0' "$ROWS" 2>/dev/null | grep -c .)"
    if [ $i -eq 0 ]; then
        args+=(--add item wud.row.$i popup.wud
               --set wud.row.$i icon.drawing=off label="All containers up to date"
                   label.color=$MUTED label.padding_left=12 label.padding_right=12)
        i=$((i + 1))
    fi
    if [ "$hidden" -gt 0 ]; then
        args+=(--add item wud.row.$i popup.wud
               --set wud.row.$i icon.drawing=off label="+$hidden rebuilds of the same version, not counted"
                   label.color=$MUTED label.font.size=11 label.padding_left=12 label.padding_right=12)
    fi
    sketchybar "${args[@]}" >/dev/null 2>&1
}

if [ "$SENDER" = "mouse.clicked" ]; then
    fill_popup
    sketchybar --set clock popup.drawing=off --set battery popup.drawing=off \
        --set volume popup.drawing=off --set homelab popup.drawing=off \
        --set "$NAME" popup.drawing=toggle
    exit 0
fi

# Fetch WUD's view, classify it on the server. Any failure: keep the last state.
JSON="$(curl -s --max-time 5 -u "$WUD_USER:$WUD_PASSWORD" "$WUD_URL/api/containers")"
[ -z "$JSON" ] && exit 0
NEW="$(printf '%s' "$JSON" | ssh -o BatchMode=yes -o ConnectTimeout=5 "$HOMELAB_HOST" \
    '~/.local/bin/wud-classify' 2>/dev/null)" || exit 0
printf '%s\n' "$NEW" | grep . > "$ROWS"

# Remember when each counted version first appeared (WUD's image date, else now);
# keyed by version so weekly rebuilds don't reset the clock.
NOW="$(date +%s)"
awk -F'\t' -v now="$NOW" 'FILENAME == ARGV[1] { seen[$1 "\t" $2] = $3; next }
    $2 == 1 { k = $1 "\t" $4; t = (k in seen) ? seen[k] : ($5 != "" ? $5 : now); print k "\t" t }' \
    "$SEEN" "$ROWS" 2>/dev/null > "$SEEN.tmp"
mv "$SEEN.tmp" "$SEEN"

COUNT="$(grep -c . "$SEEN")"
OLDEST="$(awk -F'\t' 'NR == 1 || $3 < m { m = $3 } END { print m + 0 }' "$SEEN")"

if [ "$COUNT" -eq 0 ]; then
    sketchybar --set "$NAME" drawing=off popup.drawing=off
elif [ $((NOW - OLDEST)) -ge $((STALE_DAYS * 86400)) ]; then
    sketchybar --set "$NAME" drawing=on icon.color="$GOLD" label="$COUNT" label.color="$GOLD" label.drawing=on
else
    sketchybar --set "$NAME" drawing=on icon.color="$MUTED" label="$COUNT" label.color="$MUTED" label.drawing=on
fi
