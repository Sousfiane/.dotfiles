#!/usr/bin/env bash
# GTK apps: the theme, its colour scheme, the app font and the icon theme (gsettings), and GTK 4's gtk.css,
# a link to the theme's own. An open Nautilus read gtk.css when it started and never again: it's closed and
# opened again, on its folders, where it was (reopen.sh).

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

file=$(theme_current)            # the merged theme: theme.json, the fonts picked and the palette
theme=$(<"$file")
status=0

if command -v jq >/dev/null && command -v gsettings >/dev/null; then
    GNOME=org.gnome.desktop.interface
    gsettings set $GNOME gtk-theme "$(jq -r '.gtk' "$file")"
    # each palette says which: the rose-pine GTK themes look wrong with prefer-dark, since libadwaita apps
    # then add their own dark style on top of the theme's colours
    gsettings set $GNOME color-scheme "$(jq -r '.gtkColorScheme // "default"' "$file")"
    gsettings set $GNOME font-name "$(jq -r '.font | "\(.app // .ui) \(.appPointSize)"' "$file")"
    gsettings set $GNOME icon-theme "$(jq -r '.icons' "$file")"
fi

# GTK 4 apps (Nautilus) ignore the theme setting: they read gtk-4.0/gtk.css, a link to the theme's own
if command -v jq >/dev/null; then
    css="/usr/share/themes/$(jq -r '.gtk' "$file")/gtk-4.0/gtk.css"
    link="$HOME/.config/gtk-4.0/gtk.css"
    if [[ -f $css && ( -L $link || ! -e $link ) && $(readlink "$link") != "$css" ]]; then
        mkdir -p "$(dirname "$link")"
        ln -sfn "$css" "$link"
        # an open Nautilus read gtk.css when it started and never again: it's closed and its windows opened
        # again, each on its folder (tabs come back as their window's first folder), where it was. In the
        # background
        if pgrep -x nautilus >/dev/null && command -v busctl >/dev/null; then
            setsid -f bash -c '
                export locations=$(busctl --user --json=short get-property org.freedesktop.FileManager1 \
                    /org/freedesktop/FileManager1 org.freedesktop.FileManager1 OpenWindowsWithLocations |
                    jq -r ".data[][0] // empty")
                "$1" save org.gnome.Nautilus
                nautilus -q
                while pgrep -x nautilus >/dev/null; do sleep 0.2; done
                exec "$1" start org.gnome.Nautilus "while IFS= read -r uri; do
                    [[ -n \$uri ]] && uwsm-app -- nautilus --new-window \"\$uri\"
                done <<<\"\$locations\""' _ "$(dirname "${BASH_SOURCE[0]}")/../reopen.sh" >/dev/null 2>&1
        fi
    fi
fi

exit $status
