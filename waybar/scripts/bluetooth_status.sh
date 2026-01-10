#!/usr/bin/env bash
# ===============================
# Bluetooth Menu Script for Wofi
# ===============================

set -o pipefail

# Volume memory file
VOLUME_FILE="$HOME/.config/bt-volumes.conf"
LOCK_FILE="/tmp/bt-menu-$USER.lock"

# ===============================
# Cleanup on Exit
# ===============================
cleanup() {
    # Kill any background processes from this script
    jobs -p | xargs -r kill 2>/dev/null
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT INT TERM

# Prevent multiple instances
if ! mkdir "$LOCK_FILE" 2>/dev/null; then
    notify-send "Bluetooth" "Menu already running" 2>/dev/null
    exit 1
fi

# ===============================
# Volume Management
# ===============================
save_volume() {
    local mac="$1"
    [[ -z "$mac" ]] && return 1
    
    local volume
    volume=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oP '\d+%' | head -1 | tr -d '%')
    
    [[ -z "$volume" ]] && return 1
    
    # Create config dir if it doesn't exist
    local config_dir
    config_dir=$(dirname "$VOLUME_FILE")
    [[ -d "$config_dir" ]] || mkdir -p "$config_dir"
    
    # Use atomic write with temp file
    local temp_file="${VOLUME_FILE}.tmp"
    if [[ -f "$VOLUME_FILE" ]]; then
        grep -v "^$mac=" "$VOLUME_FILE" > "$temp_file" 2>/dev/null || true
    else
        : > "$temp_file"
    fi
    
    echo "$mac=$volume" >> "$temp_file"
    mv "$temp_file" "$VOLUME_FILE"
}

restore_volume() {
    local mac="$1"
    [[ -z "$mac" || ! -f "$VOLUME_FILE" ]] && return 1
    
    local saved_volume
    saved_volume=$(grep "^$mac=" "$VOLUME_FILE" 2>/dev/null | cut -d'=' -f2)
    
    [[ -z "$saved_volume" ]] && return 1
    
    # Wait for sink to be ready with exponential backoff
    local attempt=0
    local max_attempts=8
    local wait_time=0.2
    
    while ((attempt < max_attempts)); do
        if pactl set-sink-volume @DEFAULT_SINK@ "${saved_volume}%" 2>/dev/null; then
            notify "Volume restored to ${saved_volume}%"
            return 0
        fi
        sleep "$wait_time"
        wait_time=$(awk "BEGIN {print $wait_time * 1.5}")
        ((attempt++))
    done
    
    return 1
}

# ===============================
# Get Bluetooth Status
# ===============================
get_bt_status() {
    local status
    status=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
    
    if [[ "$status" == "yes" ]]; then
        echo "ON"
    else
        echo "OFF"
    fi
}

# ===============================
# Get Connected Device
# ===============================
get_connected_device() {
    local connected
    connected=$(bluetoothctl devices Connected 2>/dev/null | head -n1)
    
    if [[ -n "$connected" ]]; then
        local name
        name=$(echo "$connected" | cut -d' ' -f3-)
        echo "Connected: $name"
    else
        echo "Connected: None"
    fi
}

# ===============================
# Notification Helper
# ===============================
notify() {
    notify-send -u normal "Bluetooth" "$1" 2>/dev/null || true
}

# ===============================
# Show Menu
# ===============================
show_menu() {
    local bt_status
    local connected
    
    bt_status=$(get_bt_status)
    connected=$(get_connected_device)
    
    cat << EOF
Bluetooth: $bt_status
$connected
────────────────────
🔵 Turn ON
🔴 Turn OFF
🔄 Toggle Power
📱 Paired Devices
🔍 Scan & Pair New
🔁 Restart Service
⚙️  Open Manager
❌ Exit
EOF
}

# ===============================
# Get Device Info
# ===============================
get_device_name() {
    local mac="$1"
    local name
    
    # Try to get name from info
    name=$(bluetoothctl info "$mac" 2>/dev/null | grep -m1 "Name:" | cut -d':' -f2- | sed 's/^[[:space:]]*//')
    
    # Fallback: extract from devices list
    if [[ -z "$name" ]]; then
        name=$(bluetoothctl devices 2>/dev/null | grep "$mac" | cut -d' ' -f3-)
    fi
    
    echo "${name:-Unknown Device}"
}

is_device_connected() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null | grep -q "Connected: yes"
}

is_device_paired() {
    local mac="$1"
    bluetoothctl info "$mac" 2>/dev/null | grep -q "Paired: yes"
}

# ===============================
# Connect Device with Proper Handling
# ===============================
connect_device() {
    local mac="$1"
    local name="$2"
    
    notify "Connecting to $name..."
    
    # Connect with timeout
    local output
    if output=$(timeout 15s bluetoothctl connect "$mac" 2>&1); then
        if echo "$output" | grep -qi "connection successful\|connected"; then
            # Wait for audio sink with progressive checks
            local count=0
            while ((count < 6)); do
                if pactl list sinks short 2>/dev/null | grep -q "bluez"; then
                    sleep 0.5  # Extra stabilization time
                    restore_volume "$mac" &
                    return 0
                fi
                sleep 0.3
                ((count++))
            done
            notify "Connected to $name"
            return 0
        fi
    fi
    
    notify "Failed to connect to $name"
    return 1
}

# ===============================
# Disconnect Device
# ===============================
disconnect_device() {
    local mac="$1"
    local name="$2"
    
    save_volume "$mac"
    
    if bluetoothctl disconnect "$mac" 2>/dev/null; then
        notify "Disconnected from $name"
        return 0
    else
        notify "Failed to disconnect from $name"
        return 1
    fi
}

# ===============================
# Save Currently Connected Volume
# ===============================
save_connected_volume() {
    local connected_mac
    connected_mac=$(bluetoothctl devices Connected 2>/dev/null | head -n1 | awk '{print $2}')
    
    [[ -n "$connected_mac" ]] && save_volume "$connected_mac"
}

# ===============================
# Handle Paired Devices Menu
# ===============================
handle_paired_devices() {
    local devices
    devices=$(bluetoothctl paired-devices 2>/dev/null)
    
    if [[ -z "$devices" ]]; then
        notify "No paired devices found"
        return
    fi
    
    # Build device list
    local device_list=""
    while IFS= read -r line; do
        local mac name icon
        mac=$(echo "$line" | awk '{print $2}')
        name=$(get_device_name "$mac")
        
        if is_device_connected "$mac"; then
            icon="✓"
        else
            icon=" "
        fi
        
        device_list+="$icon $name|$mac"$'\n'
    done <<< "$devices"
    
    # Select device
    local selected
    selected=$(echo -e "${device_list}" | wofi --dmenu --width 480 --height 300 --prompt "Select Device" --no-actions)
    
    [[ -z "$selected" ]] && return
    
    # Extract info
    local selected_mac selected_name
    selected_mac=$(echo "$selected" | rev | cut -d'|' -f1 | rev)
    selected_name=$(echo "$selected" | cut -d'|' -f1 | sed 's/^[✓ ]*//')
    
    # Show actions
    local action
    action=$(printf "Connect\nDisconnect\nRemove\nBack" | wofi --dmenu --width 300 --height 220 --prompt "$selected_name" --no-actions)
    
    case "$action" in
        Connect)
            connect_device "$selected_mac" "$selected_name"
            ;;
        Disconnect)
            disconnect_device "$selected_mac" "$selected_name"
            ;;
        Remove)
            is_device_connected "$selected_mac" && save_volume "$selected_mac"
            
            if bluetoothctl remove "$selected_mac" 2>/dev/null; then
                notify "Removed $selected_name"
            else
                notify "Failed to remove $selected_name"
            fi
            ;;
    esac
}

# ===============================
# Handle Scan and Pair
# ===============================
handle_scan() {
    notify "Scanning for devices..."
    
    # Start scan with timeout
    timeout 8s bluetoothctl scan on &>/dev/null &
    local scan_pid=$!
    
    sleep 7
    
    # Stop scan
    kill -TERM "$scan_pid" 2>/dev/null
    wait "$scan_pid" 2>/dev/null
    bluetoothctl scan off &>/dev/null
    
    # Get discovered devices
    local discovered
    discovered=$(bluetoothctl devices 2>/dev/null)
    
    if [[ -z "$discovered" ]]; then
        notify "No devices found"
        return
    fi
    
    # Build discovery list
    local disc_list=""
    while IFS= read -r line; do
        local mac name prefix
        mac=$(echo "$line" | awk '{print $2}')
        name=$(get_device_name "$mac")
        
        if is_device_paired "$mac"; then
            prefix="[P]"
        else
            prefix="   "
        fi
        
        disc_list+="$prefix $name|$mac"$'\n'
    done <<< "$discovered"
    
    # Select device
    local selected
    selected=$(echo -e "${disc_list}" | wofi --dmenu --width 480 --height 300 --prompt "Select Device ([P] = paired)" --no-actions)
    
    [[ -z "$selected" ]] && return
    
    # Extract info
    local selected_mac selected_name
    selected_mac=$(echo "$selected" | rev | cut -d'|' -f1 | rev)
    selected_name=$(echo "$selected" | cut -d'|' -f1 | sed 's/^\[P\] //' | sed 's/^   //')
    
    # Show actions based on pair status
    local action
    if [[ "$selected" == *"[P]"* ]]; then
        action=$(printf "Connect\nDisconnect\nRemove" | wofi --dmenu --width 300 --height 200 --prompt "$selected_name" --no-actions)
    else
        action=$(printf "Pair & Connect\nCancel" | wofi --dmenu --width 300 --height 150 --prompt "$selected_name" --no-actions)
    fi
    
    case "$action" in
        "Pair & Connect")
            notify "Pairing with $selected_name..."
            
            local pair_output
            if pair_output=$(timeout 20s bluetoothctl pair "$selected_mac" 2>&1); then
                if echo "$pair_output" | grep -qi "pairing successful\|paired"; then
                    bluetoothctl trust "$selected_mac" 2>/dev/null
                    sleep 0.5
                    connect_device "$selected_mac" "$selected_name"
                else
                    notify "Failed to pair with $selected_name"
                fi
            else
                notify "Pairing timed out for $selected_name"
            fi
            ;;
        Connect)
            connect_device "$selected_mac" "$selected_name"
            ;;
        Disconnect)
            disconnect_device "$selected_mac" "$selected_name"
            ;;
        Remove)
            is_device_connected "$selected_mac" && save_volume "$selected_mac"
            
            if bluetoothctl remove "$selected_mac" 2>/dev/null; then
                notify "Removed $selected_name"
            else
                notify "Failed to remove $selected_name"
            fi
            ;;
    esac
}

# ===============================
# Main Loop
# ===============================
main() {
    while true; do
        local choice
        choice=$(show_menu | wofi --dmenu --width 420 --height 350 --prompt "Bluetooth Menu" --no-actions)
        
        # Exit if nothing selected
        [[ -z "$choice" ]] && exit 0
        
        case "$choice" in
            *"Turn ON"*)
                bluetoothctl power on 2>/dev/null && notify "Bluetooth turned ON"
                ;;
                
            *"Turn OFF"*)
                save_connected_volume
                bluetoothctl power off 2>/dev/null && notify "Bluetooth turned OFF"
                ;;
                
            *"Toggle"*)
                if [[ "$(get_bt_status)" == "ON" ]]; then
                    save_connected_volume
                    bluetoothctl power off 2>/dev/null && notify "Bluetooth turned OFF"
                else
                    bluetoothctl power on 2>/dev/null && notify "Bluetooth turned ON"
                fi
                ;;
                
            *"Paired Devices"*)
                handle_paired_devices
                ;;
                
            *"Scan"*)
                handle_scan
                ;;
                
            *"Restart"*)
                save_connected_volume
                
                if sudo systemctl restart bluetooth 2>/dev/null; then
                    notify "Service restarted"
                else
                    notify "Failed to restart (need sudo)"
                fi
                ;;
                
            *"Manager"*)
                if command -v blueman-manager &>/dev/null; then
                    setsid -f blueman-manager &>/dev/null
                else
                    notify "blueman-manager not found"
                fi
                exit 0
                ;;
                
            *"Exit"*)
                exit 0
                ;;
        esac
    done
}

# Run main function
main