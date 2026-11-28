# shellcheck shell=bash
# Sourced by the theme's shell scripts (theme, merge.sh, apply.sh, apps/*.sh, tmux's theme.sh,
# spotify-themed, the spicetify step): where the theme lives and which palette is current.
#
#   source "$HOME/.config/theme/lib.sh"
#   theme_current           ~/.local/state/theme/current.json: the whole theme, what the apps read
#   theme_palette_name      "rose-pine-moon" (merge.sh, and `theme` to switch)
#   theme_write <path> <fn> a file written from what a function prints (the apps/ scripts)
#   theme_header <mark>     the note at the top of such a file

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

# writes what the function `make` prints to `path`, in one step so an app never reads half a file. Only once
# it's all there: when `make` fails, the old file stays
theme_write() {
    local path=$1 make=$2 tmp="$1.tmp"
    mkdir -p "$(dirname "$path")"
    if ! "$make" >"$tmp"; then
        rm -f "$tmp"
        echo "${0##*/}: couldn't write $path" >&2
        return 1
    fi
    mv -f "$tmp" "$path"     # a link there (into the dotfiles, from before) is replaced too, not followed
}

# the note at the top of a written file, with that format's comment mark: which apps/ script writes it
theme_header() {
    printf '%s Written by ~/.config/theme/apps/%s from ~/.config/theme/theme.json and its palette:\n' "$1" "${0##*/}"
    printf '%s edit those, since this file is replaced on every theme change.\n\n' "$1"
}
