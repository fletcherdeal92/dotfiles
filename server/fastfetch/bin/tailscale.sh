#!/bin/sh
# Tailscale up/down
state=$(tailscale status --json 2>/dev/null | jq -r '.BackendState // empty' 2>/dev/null)
case "$state" in
  Running) echo "up" ;;
  '') echo "?" ;;
  *) echo "down ($state)" ;;
esac
