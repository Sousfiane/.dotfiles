#!/bin/bash

fzf_args=(
  --multi
  --preview 'yay -Si {1} || yay -Si --aur {1}'
  --preview-label='alt-p: toggle preview | alt-j/k: scroll | tab: select'
  --preview-label-pos='bottom'
  --preview-window 'down:45%:wrap'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-d:preview-half-page-down,alt-u:preview-half-page-up'
  --bind 'alt-k:preview-up,alt-j:preview-down'
  --color 'pointer:green,marker:green'
)

# yay -Slq already lists repo + AUR when using yay as the backend
pkg_list=$(yay -Slq 2>/dev/null | sort -u)

pkg_names=$(echo "$pkg_list" | fzf "${fzf_args[@]}")

if [[ -n "$pkg_names" ]]; then
  echo "$pkg_names" | tr '\n' ' ' | xargs yay -S --noconfirm
fi

