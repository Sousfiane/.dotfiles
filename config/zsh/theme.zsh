# The shell's colours, from ~/.config/theme/theme.json and the palette it names (config/theme in the
# dotfiles):
#
#   fzf          FZF_DEFAULT_OPTS
#   ls, eza...   LS_COLORS, from vivid's theme of the same name (the palette's "vivid")
#   completion   zsh's completion list colours, which follow LS_COLORS
#
# These are environment variables, read when a program starts: zprofile sets them for the session, and zshrc
# checks again at every prompt, so a theme switch reaches open shells at their next prompt.

zmodload -F zsh/stat b:zstat

# sets them from the current palette; leaves each as it was when it can't be worked out
shell_theme() {
    local dir=$HOME/.config/theme value
    local palette="$dir/palettes/$(jq -r '.palette' "$dir/theme.json" 2>/dev/null).json"

    value=$(jq -r '.colors | [
        "--color=fg:\(.subtle),bg:\(.base),hl:\(.rose)",
        "--color=fg+:\(.text),bg+:\(.overlay),hl+:\(.rose)",
        "--color=border:\(.highlightMed),header:\(.pine),gutter:\(.base)",
        "--color=spinner:\(.gold),info:\(.foam)",
        "--color=pointer:\(.iris),marker:\(.love),prompt:\(.subtle)"
    ] | join(" ")' "$palette" 2>/dev/null)
    [[ -n $value ]] && export FZF_DEFAULT_OPTS=$value

    if (( $+commands[vivid] )); then
        value=$(vivid generate "$(jq -r '.vivid // "rose-pine"' "$palette" 2>/dev/null)" 2>/dev/null)
        [[ -n $value ]] && export LS_COLORS=$value
    fi
    # completion colours are copied from LS_COLORS when set, so they're set again with it
    [[ -o interactive ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
}

# shell_theme again, but only when a theme file changed since the last time (their modification times: no
# process started, so it's cheap enough for every prompt)
typeset -g _shell_theme_stamp=""
shell_theme_refresh() {
    local dir=$HOME/.config/theme
    local -a times
    zstat -A times +mtime -- "$dir/theme.json" "$dir"/palettes/*.json 2>/dev/null
    [[ ${times[*]} == "$_shell_theme_stamp" ]] && return
    _shell_theme_stamp=${times[*]}
    shell_theme
}
