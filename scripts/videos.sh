#!/bin/bash

dir="$HOME/.config/rofi/launcher"
theme='style-1'
videos="$HOME/Videos"

while [ -z $file ]
do
    folder=$(ls $videos | rofi -dmenu -i -theme $dir/$theme)
    [ -z $folder ] || file=$(ls $videos/$folder |  rofi -dmenu -i -theme $dir/$theme)
    [ -z $folder ] && [ -z $pdf ] && exit
done

mpv --fs=yes $videos/$folder/$file
