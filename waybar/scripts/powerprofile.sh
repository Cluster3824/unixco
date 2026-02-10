#!/bin/bash

get_current_profile() {
  powerprofilesctl get 2>/dev/null || echo "power-saver"
}

set_profile() {
  powerprofilesctl set "$1"
}

notify() {
  notify-send \
    -a "Power Profile" \
    -u low \
    "Power Profile Changed" \
    "Mode: $1"
}


toggle_profile() {
  current=$(get_current_profile)

  case "$current" in
    power-saver) new="balanced" ;;
    balanced) new="performance" ;;
    performance) new="power-saver" ;;
  esac

  set_profile "$new"
  notify "$new"
}

display_profile() {
  case "$(get_current_profile)" in
    power-saver) echo "󰾆" ;;
    balanced) echo "󰾅" ;;
    performance) echo "󰓅" ;;
  esac
}

case "$1" in
  toggle) toggle_profile ;;
  *) display_profile ;;
esac
