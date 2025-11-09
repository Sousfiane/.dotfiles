#!/usr/bin/env bash

options=" Lock session\n󰍃 Logout\n Reboot\n Shutdown"
selected=$(echo -e "$options" | wofi -S dmenu -j -H 150 -W 300)

case "$selected" in
    *Lock*)
        hyprlock
        ;;
    *Logout*)
        uwsm stop
        ;;
    *Reboot*)
        systemctl reboot
        ;;
    *Shutdown*)
        systemctl poweroff
        ;;
    *)
        exit 0
        ;;
esac

