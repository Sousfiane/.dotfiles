# shellcheck shell=bash
# Sourced by the theme's shell scripts (theme, merge.sh, apply.sh, files.sh, tmux's theme.sh,
# spotify-themed, the spicetify step): where the theme lives and which palette is current.
#
#   source "$HOME/.config/theme/lib.sh"
#   theme_current           ~/.local/state/theme/current.json: the whole theme, what the apps read
#   theme_palette_name      "rose-pine-moon" (merge.sh, and `theme` to switch)

THEME_DIR="$HOME/.config/theme"            # theme.json and palettes/ (config/theme in the dotfiles)
THEME_STATE="$HOME/.local/state/theme"     # the choices, out of the repo: palette, fonts.json
THEME_CURRENT="$THEME_STATE/current.json"  # theme.json + fonts.json + the palette, written by merge.sh

# the current palette: the state file (written by `theme`), or theme.json's default when it names none or
# one that's gone (renamed, deleted)
theme_palette_name() {
    local name
    name=$(head -n 1 "$THEME_STATE/palette" 2>/dev/null | tr -d '[:space:]') || true
    if [[ -z $name || ! -f $THEME_DIR/palettes/$name.json ]]; then
        name=$(jq -r '.palette // empty' "$THEME_DIR/theme.json" 2>/dev/null) || true
    fi
    printf '%s\n' "$name"
}

# the merged theme's path, written first if it isn't there yet (a new machine)
theme_current() {
    [[ -f $THEME_CURRENT ]] || "$THEME_DIR/merge.sh" || true
    printf '%s\n' "$THEME_CURRENT"
}
