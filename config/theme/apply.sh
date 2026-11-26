#!/usr/bin/env bash
# Brings everything up to date with theme.json. Quickshell runs this whenever the file changes (it follows
# the file itself), and steps/system.sh runs it on install.
#
#   Hyprland   reloads its config, which also rewrites hyprtoolkit's and qt6ct's files (theme_files.lua)
#   kitty      reloads its config (SIGUSR1), in every window
#   tmux       sources its config, if a server is running
#   GTK        app font and icon theme (gsettings)

theme="$HOME/.config/theme/theme.json"

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl reload >/dev/null
fi

pkill -USR1 -x kitty 2>/dev/null

if tmux info &>/dev/null; then
    tmux source-file "$HOME/.config/tmux/tmux.conf"
fi

if command -v jq >/dev/null && command -v gsettings >/dev/null; then
    font=$(jq -r '"\(.font.ui) \(.font.appPointSize)"' "$theme")
    icons=$(jq -r '.icons' "$theme")
    gsettings set org.gnome.desktop.interface font-name "$font"
    gsettings set org.gnome.desktop.interface icon-theme "$icons"
fi
