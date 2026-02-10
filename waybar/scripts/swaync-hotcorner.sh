#!/bin/bash

# Prevent repeated triggers
LOCK="/tmp/swaync_hotcorner.lock"

if [ -f "$LOCK" ]; then
  exit 0
fi

touch "$LOCK"
swaync-client --toggle-panel

# Cooldown (prevents spam)
sleep 0.8
rm -f "$LOCK"
