#!/usr/bin/env bash
# Spotify can't change theme while it runs: spotify-themed applies it (spicetify) as Spotify opens. If it's
# open now with another scheme, it's closed and opened again with the new one, where it was (reopen.sh). In
# the background, so nothing here waits.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

file=$(theme_current)            # the merged theme: theme.json, the fonts picked and the palette
theme=$(<"$file")
status=0

if pgrep -x spotify >/dev/null && command -v jq >/dev/null; then
    wanted=$(jq -r '.spicetify // ""' "$file" 2>/dev/null)
    scheme=$(awk -F' *= *' '$1=="color_scheme"{print $2; exit}' "$HOME/.config/spicetify/config-xpui.ini" 2>/dev/null)
    if [[ -n $wanted && $scheme != "$wanted" ]]; then
        setsid -f bash -c '
            "$1" save spotify
            pkill -x spotify
            while pgrep -x spotify >/dev/null; do sleep 0.2; done
            exec "$1" start spotify "uwsm-app -- $HOME/.local/bin/spotify-themed"' _ "$(dirname "${BASH_SOURCE[0]}")/../reopen.sh" >/dev/null 2>&1
    fi
fi

exit $status
