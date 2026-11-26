#!/usr/bin/env bash
# Brings everything up to date with theme.json and its palette. Quickshell runs this whenever either changes
# (it follows them itself), the `theme` command when Quickshell isn't running, and steps/system.sh on install.
#
#   Hyprland   reloads its config, which also rewrites hyprtoolkit's and qt6ct's files (theme_files.lua)
#   kitty      reloads its config (SIGUSR1), in every window
#   tmux       sources its config, if a server is running
#   GTK        theme, colour scheme, app font and icon theme (gsettings), and GTK 4's gtk.css link
#   Spotify    if it's open with another scheme, a notification offers to restart it (spotify-themed)

theme="$HOME/.config/theme/theme.json"

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl reload >/dev/null
fi

pkill -USR1 -x kitty 2>/dev/null

if tmux info &>/dev/null; then
    tmux source-file "$HOME/.config/tmux/tmux.conf"
fi

if command -v jq >/dev/null && command -v gsettings >/dev/null; then
    # the current palette: the state file (written by `theme`), or theme.json's default
    name=$(head -n 1 "$HOME/.local/state/theme/palette" 2>/dev/null | tr -d '[:space:]')
    [[ -n $name ]] || name=$(jq -r '.palette' "$theme")
    palette="$HOME/.config/theme/palettes/$name.json"
    GNOME=org.gnome.desktop.interface
    gsettings set $GNOME gtk-theme "$(jq -r '.gtk' "$palette")"
    # each palette says which: the rose-pine GTK themes look wrong with prefer-dark, since libadwaita apps
    # then add their own dark style on top of the theme's colours
    gsettings set $GNOME color-scheme "$(jq -r '.gtkColorScheme // "default"' "$palette")"
    gsettings set $GNOME font-name "$(jq -r '"\(.font.ui) \(.font.appPointSize)"' "$theme")"
    gsettings set $GNOME icon-theme "$(jq -r '.icons' "$theme")"
fi

# GTK 4 apps (Nautilus) ignore the theme setting: they read gtk-4.0/gtk.css, a link to the theme's own
if command -v jq >/dev/null; then
    css="/usr/share/themes/$(jq -r '.gtk' "$palette")/gtk-4.0/gtk.css"
    link="$HOME/.config/gtk-4.0/gtk.css"
    if [[ -f $css && ( -L $link || ! -e $link ) ]]; then
        mkdir -p "$(dirname "$link")"
        ln -sfn "$css" "$link"
    fi
fi

# Spotify can't change theme while it runs: spotify-themed applies it the next time it opens. If it's open
# now with another scheme, a notification offers to restart it (clicking it does), rather than closing it
# out of the blue. In the background, so nothing here waits for the click
if pgrep -x spotify >/dev/null && command -v jq >/dev/null; then
    wanted=$(jq -r '.spicetify // ""' "$palette" 2>/dev/null)
    scheme=$(awk -F' *= *' '$1=="color_scheme"{print $2; exit}' "$HOME/.config/spicetify/config-xpui.ini" 2>/dev/null)
    if [[ -n $wanted && $scheme != "$wanted" ]]; then
        setsid -f bash -c '
            action=$(notify-send --app-name=Spotify --icon=spotify-launcher --action=default=Restart \
                "Spotify" "Click to restart it with the new theme")
            if [[ $action == default ]]; then
                pkill -x spotify
                while pgrep -x spotify >/dev/null; do sleep 0.2; done
                "$HOME/.local/bin/spotify-themed"
            fi' >/dev/null 2>&1
    fi
fi
