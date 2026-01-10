#!/bin/bash

# Get Wi-Fi radio state
STATE=$(nmcli -t -f WIFI g)

if [ "$STATE" = "enabled" ]; then
    nmcli radio wifi off
    notify-send "Wi-Fi" "Disabled"
else
    nmcli radio wifi on
    notify-send "Wi-Fi" "Enabled"
fi
