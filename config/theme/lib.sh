# shellcheck shell=bash
# Sourced by the theme's shell scripts (theme, apply.sh, files.sh, tmux's theme.sh, spotify-themed, the
# spicetify step): where the theme lives and which palette is current. Hyprland, kitty, Quickshell and zsh
# work it out the same way in their own language.
#
#   source "$HOME/.config/theme/lib.sh"
#   theme_palette_name      "rose-pine-moon"
#   theme_palette_file      ~/.config/theme/palettes/rose-pine-moon.json

THEME_DIR="$HOME/.config/theme"            # theme.json and palettes/ (config/theme in the dotfiles)
THEME_STATE="$HOME/.local/state/theme"     # the choices, out of the repo: palette, fonts.json

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

theme_palette_file() {
    printf '%s/palettes/%s.json\n' "$THEME_DIR" "$(theme_palette_name)"
}
