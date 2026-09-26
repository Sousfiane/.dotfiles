#!/bin/bash

MAC="A8:E6:E8:04:97:29"
NAME="WH-CH720N"

# Check whether the device is known/paired
if ! bluetoothctl info "$MAC" 2>/dev/null | grep -q "Paired: yes"; then
    notify-send \
        -u critical \
        "$NAME" \
        "Device is not paired."
    exit 1
fi

# Check current connection state
if bluetoothctl info "$MAC" 2>/dev/null | grep -q "Connected: yes"; then

    # Added 3-second timeout here to prevent hanging if the headset loses signal mid-disconnect
    if timeout 3s bluetoothctl disconnect "$MAC" >/dev/null 2>&1; then
        notify-send "$NAME" "Disconnected"
    else
        notify-send -u critical "$NAME" "Failed to disconnect"
    fi

else

    # Try to connect with a 3-second maximum wait time
    if timeout 3s bluetoothctl connect "$MAC" >/dev/null 2>&1; then
        notify-send "$NAME" "Connected"
    else
        notify-send \
            -u critical \
            "$NAME" \
            "Unable to connect. Is the headset turned on and nearby?"
    fi

fi
