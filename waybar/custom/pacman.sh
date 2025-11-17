#!/bin/bash

CACHE_FILE="$HOME/.cache/waybar-pkg-cache"

updates_raw=$(checkupdates 2>/dev/null)
status=$?

if [[ $status -ne 0 ]]; then
    if [[ -f "$CACHE_FILE" ]]; then
        updates_raw=$(<"$CACHE_FILE")
    else
        updates_raw=""
    fi
else
    printf "%s\n" "$updates_raw" > "$CACHE_FILE"
fi

updates=$(echo "$updates_raw" | awk '{print $1}')
pkg_count=$(echo "$updates" | grep -c .)

if [[ -z "$updates" ]]; then
    pkg_list="System up to date"
else
    if (( pkg_count > 10 )); then
        shown=$(echo "$updates" | head -n 10)
        pkg_list="${shown//$'\n'/\\n}\\n..."
    else
        pkg_list="${updates//$'\n'/\\n}"
    fi
fi

printf '{"text":"%s","tooltip":"%s"}\n' "$pkg_count" "$pkg_list"
