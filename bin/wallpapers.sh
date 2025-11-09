#!/bin/bash

wallpapers_dir="$HOME/.wallpapers"

wallpaper=$(ls $wallpapers_dir| sed '/links.prop/d' | wofi -S dmenu -p Wallpapers)

[ -z $wallpaper ] || (echo "$wallpapers_dir/$wallpaper" > $HOME/.swaybg && pkill swaybg && uwsm-app -- swaybg -i "$(cat ~/.swaybg)" &)
