#!/bin/bash

updates=$(checkupdates | awk '{print $1}')
pkg_count=0
pkg_list="System up to date"

if [[ -n "$updates" ]]; then
    pkg_count=$(echo "$updates" | wc -l)
    if (( pkg_count > 10 )); then
        shown=$(echo "$updates" | head -n 10)
        pkg_list="${shown//$'\n'/\\n}\\n..."
    else
        pkg_list="${updates//$'\n'/\\n}"
    fi
fi

echo "{\"text\":\"$pkg_count\", \"tooltip\":\"$pkg_list\"}"
