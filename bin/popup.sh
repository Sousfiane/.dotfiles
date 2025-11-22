#!/bin/env bash

width=${1:-960}
height=${2:-540}

active=$(hyprctl activewindow -j)
pinned=$(echo "$active" | jq ".pinned")
addr=$(echo "$active" | jq -r ".address")

if [[ $pinned == "true" ]]; then
    hyprctl --batch "dispatch pin address:$addr; \
        dispatch togglefloating address:$addr; \
        dispatch tagwindow -pop address:$addr;"
elif [[ -n $addr ]]; then
    hyprctl --batch "dispatch togglefloating address:$addr; \
        dispatch resizeactive exact $width $height address:$addr; \
        dispatch centerwindow address:$addr; \
        dispatch pin address:$addr; \
        dispatch alterzorder top address:$addr; \
        dispatch tagwindow +pop address:$addr;"
fi
