# fzf's colours, from ~/.config/theme/theme.json and the palette it names (config/theme in the dotfiles).
# fzf only reads FZF_DEFAULT_OPTS when it starts: zprofile sets it for the session, and zshrc checks again at
# every prompt, so a theme switch reaches open shells at their next prompt.

zmodload -F zsh/stat b:zstat

# sets FZF_DEFAULT_OPTS from the current palette; leaves it as it was when the files can't be read
fzf_theme() {
    local dir=$HOME/.config/theme opts
    local palette="$dir/palettes/$(jq -r '.palette' "$dir/theme.json" 2>/dev/null).json"
    opts=$(jq -r '.colors | [
        "--color=fg:\(.subtle),bg:\(.base),hl:\(.rose)",
        "--color=fg+:\(.text),bg+:\(.overlay),hl+:\(.rose)",
        "--color=border:\(.highlightMed),header:\(.pine),gutter:\(.base)",
        "--color=spinner:\(.gold),info:\(.foam)",
        "--color=pointer:\(.iris),marker:\(.love),prompt:\(.subtle)"
    ] | join(" ")' "$palette" 2>/dev/null) || return
    [[ -n $opts ]] && export FZF_DEFAULT_OPTS=$opts
}

# fzf_theme again, but only when a theme file changed since the last time (their modification times: no
# process started, so it's cheap enough for every prompt)
typeset -g _fzf_theme_stamp=""
fzf_theme_refresh() {
    local dir=$HOME/.config/theme
    local -a times
    zstat -A times +mtime -- "$dir/theme.json" "$dir"/palettes/*.json 2>/dev/null
    [[ ${times[*]} == "$_fzf_theme_stamp" ]] && return
    _fzf_theme_stamp=${times[*]}
    fzf_theme
}
