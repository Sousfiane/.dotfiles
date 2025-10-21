#!/bin/bash

updates=$(checkupdates | awk '{print $1}')

pkg_count=0
pkg_list="System up to date"

if [[ -n "$updates" ]]; then
    pkg_count=$(echo "$updates" | wc -l)
    pkg_list="${updates//$'\n'/\\n}"
fi

echo "{\"text\":\"$pkg_count\", \"tooltip\":\"$pkg_list\"}"

