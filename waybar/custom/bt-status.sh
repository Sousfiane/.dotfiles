#!/usr/bin/env bash

# Map kernel power supplies by MAC address
declare -A batteries
for d in /sys/class/power_supply/*; do
    [[ -f $d/capacity && $d =~ ([[:xdigit:]]{2}[:-]){5}[[:xdigit:]]{2} ]] || continue
    mac=${BASH_REMATCH[0]//-/:}
    batteries[${mac^^}]=$(<"$d/capacity")
done

tooltip=()

# Fetch connected devices and batteries
while read -r _ mac name; do
    [[ $mac ]] || continue

    # Check BlueZ first, then fall back to sysfs kernel battery
    bat=$(bluetoothctl info "$mac" 2>/dev/null | 
        sed -n 's/.*Battery Percentage:.*(\([0-9]*\)).*/\1/p')
    bat=${bat:-${batteries[${mac^^}]}}

    if [[ $bat ]]; then
        tooltip+=("$(printf "%-25s %3s%%" "$name" "$bat")")
    else
        tooltip+=("$name")
    fi
done < <(bluetoothctl devices Connected 2>/dev/null)

# Output JSON state for Waybar
if ! bluetoothctl show 2>/dev/null | grep -qi "Powered: yes"; then
    printf '{"text":"󰂲","tooltip":"Bluetooth Off"}\n'
elif ((${#tooltip[@]})); then
    tooltip_str=$(IFS=$'\n'; echo "${tooltip[*]}")
    printf '{"text":"󰂱","tooltip":%s}\n' "$(printf '%s' "$tooltip_str" | jq -Rs .)"
else
    printf '{"text":"","tooltip":"Disconnected"}\n'
fi
