#!/usr/bin/env bash
# Spotify themed with spicetify. Only the choices live in the repo (here, and the Themes and Extensions
# folders): spicetify keeps its own config-xpui.ini in ~/.config/spicetify, out of the repo, because it
# writes the Spotify and spicetify versions into it on every backup.
#
# Spotify has to have been opened once first (spotify-launcher downloads it then). Run this again after a
# Spotify update, which undoes the theme.

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

command -v spicetify >/dev/null || fail "spicetify isn't installed (it's in packages/apps.txt: run the packages step first)"

SPOTIFY="$HOME/.local/share/spotify-launcher/install/usr/share/spotify"
PREFS="$HOME/.config/spotify/prefs"

if [[ ! -d $SPOTIFY || ! -f $PREFS ]]; then
    warn "Spotify hasn't been opened yet: open it once, close it, then run install.sh spicetify"
    exit 0
fi

# the Ziro colour scheme that goes with the current palette (theme.json); Spotify can't switch live, so
# run this step again after `theme`
SCHEME=$(jq -r '.spicetify' "$HOME/.config/theme/palettes/$(jq -r '.palette' "$HOME/.config/theme/theme.json").json" 2>/dev/null)
[[ -n $SCHEME && $SCHEME != null ]] || SCHEME=rose-pine

# fields left out keep spicetify's defaults
spicetify -q config \
    spotify_path "$SPOTIFY" \
    prefs_path "$PREFS" \
    current_theme Ziro \
    color_scheme "$SCHEME" \
    sidebar_config 0 \
    extensions adblock.js
success "spicetify configured"

# stock Spotify (first run, or just updated): spicetify backs it up again, then themes it. Already themed:
# backup refuses, and applying again picks up the config
if spicetify -q backup apply 2>/dev/null; then
    success "Spotify backed up and themed"
elif spicetify -q apply 2>/dev/null; then
    success "Spotify themed again"
else
    # Spotify updated over a patched install: neither works until it's stock again. spotify-launcher
    # downloads it afresh (deleting the install folder isn't enough: its state.json would skip the download)
    info "Spotify is half patched: downloading it again"
    spotify-launcher --force-update --no-exec >/dev/null 2>&1 || fail "spotify-launcher couldn't download Spotify"
    spicetify -q backup apply
    success "Spotify downloaded again, backed up and themed"
fi
