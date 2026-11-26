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

GNOME="org.gnome.desktop.interface"
gsettings set $GNOME gtk-theme "rose-pine-gtk"
gsettings set $GNOME color-scheme "light-dark"
# the app font and icon theme come from theme.json (config/theme/apply.sh, also run when it changes)
"$DOTFILES/config/theme/apply.sh"
success "GTK theme set"

# GTK 4 apps (Nautilus) ignore the theme setting: they read this file
if [[ -e "$HOME/.config/gtk-4.0/gtk.css" || -L "$HOME/.config/gtk-4.0/gtk.css" ]]; then
    success "GTK 4 theme already linked"
else
    mkdir -p "$HOME/.config/gtk-4.0"
    ln -s /usr/share/themes/rose-pine-gtk/gtk-4.0/gtk.css "$HOME/.config/gtk-4.0/gtk.css"
    success "GTK 4 theme linked"
fi
