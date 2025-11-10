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
  --color 'pointer:yellow,marker:yellow'
)

pkg_list=$(yay -Sy >/dev/null && yay -Qu 2>/dev/null | awk '{print $1}')

if [[ -z "$pkg_list" ]]; then
  echo "System is already up to date."
  exit 0
fi

pkg_names=$(echo "$pkg_list" | awk '{print $1}' | fzf "${fzf_args[@]}")
# capture fzf exit code (0=OK, 130=ESC/Ctrl-C)
fzf_exit=$?

# If user cancelled with ESC or Ctrl-C, exit gracefully
if [[ $fzf_exit -ne 0 ]]; then
  exit 0
fi

# If user pressed Enter with no selection → full upgrade
if [[ -z "$pkg_names" ]]; then
  yay -Syu --noconfirm
else
  echo "$pkg_names" | tr '\n' ' ' | xargs yay -S --noconfirm
fi

