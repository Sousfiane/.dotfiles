#!/usr/bin/env bash
# Brings everything up to date with theme.json and its palette. Quickshell runs this whenever either changes
# (it follows them itself), the `theme` command when Quickshell isn't running, and steps/system.sh on install.
#
#   files      hyprtoolkit's and qt6ct's own files, written again (files.sh)
#   Hyprland   reloads its config, for its own colours
#   kitty      reloads its config (SIGUSR1), in every window
#   tmux       sources its config, if a server is running
#   GTK        theme, colour scheme, app font and icon theme (gsettings), and GTK 4's gtk.css link
#   Spotify    if it's open with another scheme, it restarts with the new one (spotify-themed)
#   Discord    follows by itself (files.sh writes its palette); this only makes sure the palette is enabled

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

theme="$THEME_DIR/theme.json"
fonts="$THEME_STATE/fonts.json"    # the fonts picked in the theme picker, over theme.json's
palette=$(theme_palette_file)      # every part below that reads it checks for jq first

"$(dirname "${BASH_SOURCE[0]}")/files.sh"

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl reload >/dev/null
fi

pkill -USR1 -x kitty 2>/dev/null

if tmux info &>/dev/null; then
    tmux source-file "$HOME/.config/tmux/tmux.conf"
fi

if command -v jq >/dev/null && command -v gsettings >/dev/null; then
    GNOME=org.gnome.desktop.interface
    gsettings set $GNOME gtk-theme "$(jq -r '.gtk' "$palette")"
    # each palette says which: the rose-pine GTK themes look wrong with prefer-dark, since libadwaita apps
    # then add their own dark style on top of the theme's colours
    gsettings set $GNOME color-scheme "$(jq -r '.gtkColorScheme // "default"' "$palette")"
    [[ -r $fonts ]] || fonts=/dev/null
    gsettings set $GNOME font-name "$(jq -rs '(.[0].font + (.[1] // {})) | "\(.app // .ui) \(.appPointSize)"' "$theme" "$fonts")"
    gsettings set $GNOME icon-theme "$(jq -r '.icons' "$theme")"
fi

# GTK 4 apps (Nautilus) ignore the theme setting: they read gtk-4.0/gtk.css, a link to the theme's own
if command -v jq >/dev/null; then
    css="/usr/share/themes/$(jq -r '.gtk' "$palette")/gtk-4.0/gtk.css"
    link="$HOME/.config/gtk-4.0/gtk.css"
    if [[ -f $css && ( -L $link || ! -e $link ) && $(readlink "$link") != "$css" ]]; then
        mkdir -p "$(dirname "$link")"
        ln -sfn "$css" "$link"
        # an open Nautilus read gtk.css when it started and never again: it's closed and its windows opened
        # again, each on its folder (tabs come back as their window's first folder). In the background
        if pgrep -x nautilus >/dev/null && command -v busctl >/dev/null; then
            setsid -f bash -c '
                locations=$(busctl --user --json=short get-property org.freedesktop.FileManager1 \
                    /org/freedesktop/FileManager1 org.freedesktop.FileManager1 OpenWindowsWithLocations |
                    jq -r ".data[][0] // empty")
                nautilus -q
                while pgrep -x nautilus >/dev/null; do sleep 0.2; done
                while IFS= read -r uri; do
                    [[ -n $uri ]] && uwsm-app -- nautilus --new-window "$uri"
                done <<<"$locations"' >/dev/null 2>&1
        fi
    fi
fi

# Spotify can't change theme while it runs: spotify-themed applies it as it opens. If it's open now with
# another scheme, it's closed and opened again with the new one. In the background, so nothing here waits
if pgrep -x spotify >/dev/null && command -v jq >/dev/null; then
    wanted=$(jq -r '.spicetify // ""' "$palette" 2>/dev/null)
    scheme=$(awk -F' *= *' '$1=="color_scheme"{print $2; exit}' "$HOME/.config/spicetify/config-xpui.ini" 2>/dev/null)
    if [[ -n $wanted && $scheme != "$wanted" ]]; then
        setsid -f bash -c '
            pkill -x spotify
            while pgrep -x spotify >/dev/null; do sleep 0.2; done
            uwsm-app -- "$HOME/.local/bin/spotify-themed"' >/dev/null 2>&1
    fi
fi

# Discord: rin's Rosé Pine as an online theme (its link, so it stays up to date), with files.sh's
# palette.theme.css over it, which Vesktop reloads by itself. Both are put in Vesktop's settings when
# missing, only while it's closed: it keeps its settings in memory and would save over the change
vesktop="$HOME/.config/vesktop/settings/settings.json"
rin=https://raw.githubusercontent.com/baconeko/rose-pine-discord/refs/heads/main/dist/rin-rose-pine.theme.css
if [[ -f $vesktop ]] && command -v jq >/dev/null && ! pgrep -x vesktop >/dev/null &&
    ! jq -e --arg rin "$rin" '(.themeLinks // [] | index($rin)) and (.enabledThemes // [] | index("palette.theme.css"))' \
        "$vesktop" >/dev/null 2>&1; then
    jq --arg rin "$rin" '
        .themeLinks = ((.themeLinks // []) - [$rin] + [$rin])
        | .enabledThemes = ((.enabledThemes // []) - ["palette.theme.css"] + ["palette.theme.css"])' \
        "$vesktop" >"$vesktop.tmp" && mv -f "$vesktop.tmp" "$vesktop" || rm -f "$vesktop.tmp"
fi
