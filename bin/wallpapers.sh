#!/usr/bin/env bash

WALLPAPERS="$HOME/.wallpapers"
STATE_FILE="$HOME/.swaybg"

selected=$(
    ls -1 "$WALLPAPERS" |
    grep -v '^links\.prop$' |
    wofi -S dmenu -p "Wallpapers" --cache-file=/dev/null
)

[[ -z "$selected" ]] && exit 0

wallpaper="$WALLPAPERS/$selected"

printf '%s\n' "$wallpaper" > "$STATE_FILE"

pkill -x swaybg 2>/dev/null || true

setsid uwsm-app -- swaybg  -i "$wallpaper"  >/dev/null 2>&1 &
