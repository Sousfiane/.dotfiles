#!/bin/env bash

WALLPAPERS="$HOME/.wallpapers"

selected=$(ls $WALLPAPERS| sed '/links.prop/d' | wofi -S dmenu -p Wallpapers --cache-file=/dev/null)

[[ -z "$selected" ]] && exit 0

echo "$WALLPAPERS/$selected" > $HOME/.swaybg
pkill swaybg
setsid uwsm-app -- swaybg -i "$(cat ~/.swaybg)" >/dev/null 2>&1 &
