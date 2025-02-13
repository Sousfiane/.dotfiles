#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    [[ $1 == "." ]] && selected=$(pwd) || selected=$1
else
    selected=$(fd -t d --follow --search-path $HOME/dev/ --search-path $HOME/Nextcloud/Documents --search-path $HOME/.dotfiles/ --max-depth 1 | fzf)
fi

if [[ -z $selected ]]; then
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
