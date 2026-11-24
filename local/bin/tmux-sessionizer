#!/usr/bin/env bash

preview='
    dir={}

    printf "%s\n" "${dir##*/}"
    printf "%s\n\n" "$dir"

    # Rosé Pine ANSI Escape Codes
    pine="\033[38;2;49;116;143m"
    gold="\033[38;2;246;193;119m"
    foam="\033[38;2;156;207;216m"
    reset="\033[0m"

    if git -C "$dir" rev-parse --is-inside-work-tree &>/dev/null; then
        branch=$(git -C "$dir" branch --show-current)

        printf "%b󰊢  %s%b" "$pine" "${branch:-detached}" "$reset"

        if [[ -n $(git -C "$dir" status --porcelain) ]]; then
            printf "  %b● changes%b\n" "$gold" "$reset"
        else
            printf "  %b✓ clean%b\n" "$foam" "$reset"
        fi

        printf "\n"
    fi

    printf "Files\n\n"

    (
        cd "$dir" || exit
        tree \
            -C \
            -L 4 \
            -I ".git" \
            --dirsfirst
    )
'

fzf_args=(
    --ansi
    --height=100%
    --layout=reverse
    --border
    --preview="$preview"
    --preview-label='project'
    --preview-label-pos=bottom
    --preview-window='right:50%:wrap'
    --bind='alt-j:preview-down,alt-k:preview-up'
    --bind='alt-d:preview-half-page-down,alt-u:preview-half-page-up'
    --color='pointer:#eb6f92,marker:#eb6f92'
)

if [[ $# -eq 1 ]]; then
    [[ $1 == "." ]] && selected=$(pwd) || selected=$1
else
    selected=$(
        fd \
            -t d \
            --follow \
            --search-path "$HOME/dev/" \
            --search-path "$HOME/.dotfiles/" \
            --max-depth 1 |
        fzf "${fzf_args[@]}"
    )
fi

if [[ -z "$selected" ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr -d .)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s $selected_name -c $selected
    exit 0
fi

if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected
fi

tmux switch-client -t $selected_name 2> /dev/null || tmux a -t $selected_name
