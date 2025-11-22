#!/bin/env bash

fzf_args=(
  --ansi
  --preview 'nvcat {1}'
  --preview-label='alt-j/k: scroll, tab: multi-select'
  --preview-label-pos='bottom'
  --preview-window 'right:45%:wrap'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
  --color 'pointer:red,marker:red'
)

if [[ $(pwd) == $HOME ]]; then
    selected=$(fd -L -t f --follow --search-path $HOME --search-path $DOTFILES | fzf "${fzf_args[@]}")
else
    selected=$(fd -L -t f | fzf "${fzf_args[@]}")
fi

[[ -z $selected ]] || nvim $selected
