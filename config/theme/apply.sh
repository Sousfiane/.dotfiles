#!/usr/bin/env bash
# Brings every app up to date with the theme: theme.json, the fonts picked and the current palette.
# theme.service runs this whenever one of them changes (theme.path watches them, install/units), the
# `theme` command when that isn't running, and steps/system.sh on install (--force).
#
#   apply.sh            only when the theme changed
#   apply.sh --force    every app, changed or not
#
# First the merged theme every app reads, ~/.local/state/theme/current.json (merge.sh): when it can't be
# made (a file that doesn't parse), or didn't change (a file saved as it was), nothing else happens. Then
# each app's own script in apps/, which does
# all that app needs and nothing else: writes the files it can only read in its own format, then reloads
# it, or restarts it where it was when it only reads them as it starts (reopen.sh):
#
#   discord    its palette over rin's Rosé Pine theme; Vesktop reloads it by itself
#   gtk        theme, colour scheme, font and icons (gsettings), GTK 4's gtk.css; Nautilus restarts
#   hyprland   hyprtoolkit's file; Hyprland reloads
#   kitty      reloads (it reads the theme itself)
#   qt         hyprqt6engine's files and kdeglobals
#   spotify    restarts with the new spicetify scheme
#   tmux       sources its config (it reads the theme itself)
#   zen        its userChrome.css, userContent.css, user.js and Dark Reader's colours; restarts
#
# Quickshell, Neovim and zsh follow current.json by themselves. A new app is a new script in apps/.

dir="$(dirname "${BASH_SOURCE[0]}")"

"$dir/merge.sh"
case $? in
0) ;;
3) [[ ${1:-} == --force ]] || exit 0 ;;
*) exit 1 ;;
esac

status=0
for app in "$dir"/apps/*.sh; do
    if ! "$app"; then
        echo "apply.sh: ${app##*/} failed" >&2
        status=1
    fi
done
exit $status
