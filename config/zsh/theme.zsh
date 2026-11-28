# The shell's colours, from the merged theme (~/.local/state/theme/current.json: theme.json in config/theme,
# the fonts picked and the current palette, put together by merge.sh):
#
#   fzf          FZF_DEFAULT_OPTS
#   ls, eza...   LS_COLORS, from vivid's theme of the same name (the palette's "vivid")
#   completion   zsh's completion list colours, which follow LS_COLORS
#
# These are environment variables, read when a program starts: zprofile sets them for the session, and zshrc
# checks again before every command (and before fzf's key bindings and tab completion, which run inside the
# prompt), so a theme switch reaches open shells with the next thing they run.

zmodload -F zsh/stat b:zstat

# sets them from the current palette; leaves each as it was when it can't be worked out
shell_theme() {
    local value palette=$HOME/.local/state/theme/current.json
    # written first if it isn't there yet (a new machine)
    [[ -f $palette ]] || $HOME/.config/theme/merge.sh 2>/dev/null

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

# shell_theme again, but only when the merged theme changed since the last time: merge.sh writes a new file
# for each change, so its inode tells, even two changes within the same second (no process started, so it's
# cheap enough for every command)
typeset -g _shell_theme_stamp=""
shell_theme_refresh() {
    local -A st
    zstat -H st -- "$HOME/.local/state/theme/current.json" 2>/dev/null
    local stamp="${st[inode]}:${st[mtime]}"
    [[ $stamp == "$_shell_theme_stamp" ]] && return
    _shell_theme_stamp=$stamp
    shell_theme
}

# makes each of these zle widgets run shell_theme_refresh first: widgets run inside the prompt, with no
# preexec before them (fzf's ctrl+t, ctrl+r, alt+c and tab completion)
shell_theme_widgets() {
    local w fn
    for w in "$@"; do
        fn=${widgets[$w]#user:}
        [[ $widgets[$w] == user:* && $fn != _shell_theme_widget_* ]] || continue
        functions[_shell_theme_widget_$w]="shell_theme_refresh; $fn \"\$@\""
        zle -N $w _shell_theme_widget_$w
    done
}
