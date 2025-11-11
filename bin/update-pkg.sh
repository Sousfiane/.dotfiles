#!/bin/env bash

fzf_args=(
    --multi
    --preview 'echo {} | grep -q "upgrade" && echo "This will upgrade all packages on your system. Be careful!" || yay -Si {1} || yay -Si --aur {1}'
    --preview-label='alt-p: toggle preview | alt-j/k: scroll | tab: select'
    --preview-label-pos='bottom'
    --preview-window 'down:45%:wrap'
    --bind 'alt-p:toggle-preview'
    --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
    --bind 'alt-k:preview-up,alt-j:preview-down'
    --color 'pointer:yellow,marker:yellow'
)

yay -Sy 
pkg_list=$(yay -Qu 2>/dev/null | awk '{print $1}')

if [[ -z "$pkg_list" ]]; then
    echo "System is already up to date."
    sleep 1
    exit 0
fi

pkg_list="Full system upgrade
$pkg_list"

selection=$(echo "$pkg_list" | fzf "${fzf_args[@]}")
fzf_exit=$?

if [[ $fzf_exit -ne 0 ]]; then
    exit 0
fi

if [[ "$selection" == "Full system upgrade" ]]; then
    yay -Syu --noconfirm
else
    echo "$selection" | tr '\n' ' ' | xargs yay -S --noconfirm
fi

