#!/bin/bash

# =======================
# Wi-Fi Menu Script
# Works like Windows Wi-Fi settings
# =======================

# Requires: nmcli, rofi (or wofi), notify-send

# Function: Toggle Wi-Fi on/off
toggle_wifi() {
    if nmcli radio wifi | grep -q "enabled"; then
        nmcli radio wifi off
        notify-send "Wi-Fi Disabled"
    else
        nmcli radio wifi on
        notify-send "Wi-Fi Enabled"
    fi
}

# Function: Disconnect current Wi-Fi
disconnect_wifi() {
    ACTIVE=$(nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2)
    if [ -n "$ACTIVE" ]; then
        nmcli con down id "$ACTIVE" && notify-send "Disconnected from $ACTIVE"
    else
        notify-send "No active Wi-Fi to disconnect"
    fi
}

# Function: Forget a saved Wi-Fi
forget_wifi() {
    SAVED=$(nmcli -t -f NAME connection show | rofi -dmenu -p "Select saved network to forget")
    if [ -n "$SAVED" ]; then
        nmcli connection delete "$SAVED" && notify-send "Forgot network $SAVED"
    fi
}

# Function: Connect to a network
connect_wifi() {
    SSID=$1
    SECURITY=$2

    # Check if password required
    if [ "$SECURITY" != "--" ]; then
        PASSWORD=$(rofi -dmenu -password -p "Password for $SSID")
        if [ -z "$PASSWORD" ]; then
            notify-send "Cancelled connection"
            return
        fi
        nmcli dev wifi connect "$SSID" password "$PASSWORD" && notify-send "Connected to $SSID" || notify-send "Failed to connect to $SSID"
    else
        nmcli dev wifi connect "$SSID" && notify-send "Connected to $SSID" || notify-send "Failed to connect to $SSID"
    fi
}

# Function: Show current Wi-Fi status
show_status() {
    ACTIVE=$(nmcli -t -f ACTIVE,SSID,DEVICE,IP4 dev wifi | grep '^yes')
    if [ -n "$ACTIVE" ]; then
        SSID=$(echo "$ACTIVE" | cut -d: -f2)
        DEVICE=$(echo "$ACTIVE" | cut -d: -f3)
        IP=$(echo "$ACTIVE" | cut -d: -f4)
        notify-send "Connected to $SSID on $DEVICE ($IP)"
    else
        notify-send "Not connected to any Wi-Fi"
    fi
}

# =======================
# Build Wi-Fi menu
# =======================
menu_items="Toggle Wi-Fi\nDisconnect\nForget network\nStatus\n"

# List available Wi-Fi networks
nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list | awk -F: '{
    if($1=="") next;
    active="";
    cmd="nmcli -t -f ACTIVE,SSID dev wifi | grep -q \047^yes:"$1"\047";
    if(system(cmd)==0) active="*";
    printf "%s %s [%s%%] (%s)\n", active, $1, $2, $3;
}' >> /tmp/wifi_menu_list.txt

menu_items+=$(cat /tmp/wifi_menu_list.txt)

# Show menu via rofi (replace with wofi if you want)
CHOICE=$(echo -e "$menu_items" | rofi -dmenu -i -p "Wi-Fi Menu")

# =======================
# Handle choice
# =======================
case "$CHOICE" in
    "Toggle Wi-Fi")
        toggle_wifi
        ;;
    "Disconnect")
        disconnect_wifi
        ;;
    "Forget network")
        forget_wifi
        ;;
    "Status")
        show_status
        ;;
    *)
        # Remove leading * if network is active
        SSID=$(echo "$CHOICE" | sed 's/^\* //; s/ .*$//')
        SECURITY=$(nmcli -t -f SSID,SECURITY dev wifi | grep "^$SSID" | cut -d: -f2)
        if [ -n "$SSID" ]; then
            connect_wifi "$SSID" "$SECURITY"
        fi
        ;;
esac

# Clean up
rm -f /tmp/wifi_menu_list.txt
