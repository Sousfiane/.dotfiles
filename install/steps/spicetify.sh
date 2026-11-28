#!/usr/bin/env bash
# Spotify themed with spicetify. Only the choices live in the repo (here, and the Themes and Extensions
# folders): spicetify keeps its own config-xpui.ini in ~/.config/spicetify, out of the repo, because it
# writes the Spotify and spicetify versions into it on every backup.
#
# Spotify has to have been opened once first (spotify-launcher downloads it then). After that, spotify-themed
# (Spotify's menu entry) runs this again whenever a Spotify update or a palette change needs it.

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

command -v spicetify >/dev/null || fail "spicetify isn't installed (it's in packages/apps.txt: run the packages step first)"

SPOTIFY="$HOME/.local/share/spotify-launcher/install/usr/share/spotify"
PREFS="$HOME/.config/spotify/prefs"

if [[ ! -d $SPOTIFY || ! -f $PREFS ]]; then
    warn "Spotify hasn't been opened yet: open it once, close it, then run install.sh spicetify"
    exit 0
fi

# the Ziro colour scheme that goes with the current palette; spotify-themed runs this step again when the
# palette changes
source "$DOTFILES/config/theme/lib.sh"
SCHEME=$(jq -r '.spicetify' "$(theme_current)" 2>/dev/null)
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

# spicetify restarts Spotify after applying, starting it even when it wasn't open. spotify-themed starts it
# itself right after, so it asks for no restart (SPICETIFY_NO_RESTART=1)
NO_RESTART=()
[[ -n ${SPICETIFY_NO_RESTART:-} ]] && NO_RESTART=(-n)

# stock Spotify (first run, or just updated): spicetify backs it up again, then themes it. Already themed:
# backup refuses, and applying again picks up the config
if spicetify -q "${NO_RESTART[@]}" backup apply 2>/dev/null; then
    success "Spotify backed up and themed"
elif spicetify -q "${NO_RESTART[@]}" apply 2>/dev/null; then
    success "Spotify themed again"
else
    # Spotify updated over a patched install: neither works until it's stock again. spotify-launcher
    # downloads it afresh (deleting the install folder isn't enough: its state.json would skip the download)
    info "Spotify is half patched: downloading it again"
    spotify-launcher --force-update --no-exec >/dev/null 2>&1 || fail "spotify-launcher couldn't download Spotify"
    spicetify -q "${NO_RESTART[@]}" backup apply
    success "Spotify downloaded again, backed up and themed"
fi

# Spotify's menu entry (and the dock's pin) opens it through spotify-themed, which applies the theme again
# when Spotify was updated or the palette changed. Same id as the system entry, so it takes its place
entry="$HOME/.local/share/applications/spotify-launcher.desktop"
if [[ ! -e $entry ]] || grep -q 'spotify-themed' "$entry"; then
    mkdir -p "$(dirname "$entry")"
    sed "s|^Exec=spotify-launcher|Exec=$HOME/.local/bin/spotify-themed|; s|^TryExec=spotify-launcher|TryExec=$HOME/.local/bin/spotify-themed|" \
        /usr/share/applications/spotify-launcher.desktop >"$entry"
    success "Spotify opens through spotify-themed"
else
    warn "${entry/#$HOME/\~} exists and isn't ours: left as it is"
fi
