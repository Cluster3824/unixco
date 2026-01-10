#!/bin/bash

# Check if Bluetooth is powered on
if bluetoothctl show | grep -q "Powered: yes"; then
    bluetoothctl power off
else
    bluetoothctl power on
fi