#!/bin/env bash

wallpapers_dir="$HOME/.wallpapers"

wallpaper=$(ls $wallpapers_dir| sed '/links.prop/d' | wofi -S dmenu -p Wallpapers --cache-file=/dev/null)

[[ -z "$wallpaper" ]] && exit 0

echo "$wallpapers_dir/$wallpaper" > $HOME/.swaybg
pkill swaybg
setsid uwsm-app -- swaybg -i "$(cat ~/.swaybg)" >/dev/null 2>&1 &
