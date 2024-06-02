#!/bin/bash

dir="$HOME/.config/rofi/launcher"
theme='style-1'
wallpapers_dir="$HOME/.wallpapers"

wallpaper=$(ls $wallpapers_dir| sed '/links.prop/d' | rofi -dmenu -i -theme $dir/$theme)

[ -z $wallpaper ] || feh --bg-fill $wallpapers_dir/$wallpaper
