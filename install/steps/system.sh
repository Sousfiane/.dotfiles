#!/usr/bin/env bash
# the user's side of the system: zsh as the shell, the GTK theme

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

# ---------- zsh as the login shell ----------

zsh_path=$(command -v zsh) || fail "zsh isn't installed (it's in packages/apps.txt: run the packages step first)"
if [[ $(getent passwd "$USER" | cut -d: -f7) == "$zsh_path" ]]; then
    success "zsh already the login shell"
else
    info "Making zsh the login shell (asks for your password)"
    chsh -s "$zsh_path"
    success "zsh is the login shell (from the next login)"
fi

# ---------- GTK theme ----------

# the GTK theme (GTK 4 too), light or dark, app font and icons come from theme.json and its palette
# (config/theme/apply.sh, also run whenever they change)
"$DOTFILES/config/theme/apply.sh" --force
success "GTK theme set"
