#!/usr/bin/env bash

set -o pipefail

# Ensure DOTFILES is set
if [ -z "${DOTFILES:-}" ]; then
    echo "Error: DOTFILES environment variable is not set."
    echo "Please run this script through install-all.sh or export DOTFILES manually."
    exit 1
fi

source "$DOTFILES/install/utils/messages.sh"

GNOME="org.gnome.desktop.interface"

info "Applying Rose Pine theme..."

gsettings set $GNOME gtk-theme "rose-pine-gtk"
gsettings set $GNOME icon-theme "rose-pine-dawn-icons"
gsettings set $GNOME font-name "Adwaita Sans 11"
gsettings set $GNOME color-scheme "default"

# Nautilus fix
if [ ! -f $HOME/.config/gtk-4.0/gtk.css ]; then
    mkdir -p $HOME/.config/gtk-4.0
    ln -s /usr/share/themes/rose-pine-gtk/gtk-4.0/gtk.css $HOME/.config/gtk-4.0
fi

success "Rose Pine theme installed."
