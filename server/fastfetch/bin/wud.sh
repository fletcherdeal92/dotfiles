#!/bin/sh
# Pending image updates from What's Up Docker (notify-only). Credentials stay in the
# stack's .env on the server; 1 s timeout, "?" on any failure.
ENV="$HOME/docker/wud/.env"
[ -f "$ENV" ] || { echo "?"; exit 0; }
. "$ENV"
n=$(curl -s --max-time 1 -u "$WUD_AUTH_ADMIN_USER:$WUD_AUTH_ADMIN_PASSWORD" http://localhost:3010/api/containers \
    | jq '[.[] | select(.updateAvailable)] | length' 2>/dev/null)
case "$n" in
  ''|*[!0-9]*) echo "?" ;;
  0) echo "all images current" ;;
  1) echo "1 image update" ;;
  *) echo "$n image updates" ;;
esac
