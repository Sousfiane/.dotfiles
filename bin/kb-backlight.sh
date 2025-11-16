#!/bin/env bash

dev=/sys/class/leds/smc::kbd_backlight

brightnessctl -d smc::kbd_backlight s "$1"

current=$(cat "$dev/brightness")
max=$(cat "$dev/max_brightness")
percent=$(printf "%.1f" "$(awk -v c="$current" -v m="$max" 'BEGIN{print (c/m)}')")
echo $percent

if [[ "$percent" == "0.0" ]];then
    swayosd-client --custom-message=" " --custom-icon=kb-backlight-symbolic
else
    swayosd-client --custom-progress="$percent" --custom-icon=kb-backlight-symbolic
fi

