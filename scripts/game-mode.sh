#!/usr/bin/env bash

MONITOR="HDMI-A-1"
RESOLUTION="3840x2160@60"
POSITION="-3840x0"
GAME_WORKSPACE="10"

# Define your sinks
AUDIO_SINK_NORMAL="alsa_output.usb-Yamaha_Corporation_Steinberg_UR22-00.analog-stereo"
AUDIO_SINK_TV="alsa_output.pci-0000_01_00.1.hdmi-stereo-extra1"

# Check if monitor is active
MONITOR_ACTIVE=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$MONITOR\") | .dpmsStatus")

if [[ "$MONITOR_ACTIVE" == "true" ]]; then
    echo "Disabling game mode (turning off $MONITOR)..."

    # Switch back to normal sink
    echo "Switching audio to sound card ($AUDIO_SINK_NORMAL)..."
    pactl set-default-sink "$AUDIO_SINK_NORMAL"

    # Turn off TV
    hyprctl keyword monitor "$MONITOR,disable"
    exit 0
else
    echo "Enabling game mode on $MONITOR..."

    # Turn on the TV
    hyprctl keyword monitor "$MONITOR,$RESOLUTION,$POSITION,1"
    sleep 2

    # Set as primary for Xwayland
    xrandr --output "$MONITOR" --primary

    # Switch audio to TV
    echo "Switching audio to TV ($AUDIO_SINK_TV)..."
    pactl set-default-sink "$AUDIO_SINK_TV"

    # Focus the TV monitor and move to game workspace
    hyprctl dispatch focusmonitor "$MONITOR"
    hyprctl dispatch workspace "$GAME_WORKSPACE"

    # Launch Steam Big Picture
    if pgrep -x "steam" > /dev/null; then
        echo "Steam is already running; switching to Big Picture..."
        steam steam://open/bigpicture &
    else
        echo "Launching Steam in Big Picture mode..."
        steam -tenfoot >/dev/null 2>&1 &
    fi
fi

