#!/usr/bin/env bash

set -euo pipefail

# Ensure DOTFILES is set
if [ -z "${DOTFILES:-}" ]; then
    echo "Error: DOTFILES environment variable is not set."
    echo "Please run this script through install-all.sh or export DOTFILES manually."
    exit 1
fi

source $DOTFILES/install/utils/messages.sh

PACKAGE_LIST_DIR=$DOTFILES/install/packages

# Enable multilib for steam
info "Checking if multilib repository is enabled..."

if grep -q "^\[multilib\]" /etc/pacman.conf; then
    success "Multilib is already enabled."
else
    info "Enabling multilib repository..."
    sudo sed -i '/^\#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    sudo pacman -Sy --noconfirm
    success "Multilib repository enabled."
fi

# Install base packages
base_list=$PACKAGE_LIST_DIR/base.packages
info "Installing base packages"
yay -S --noconfirm --needed - < "$base_list"
success "Base Packages installed"

# archinstall's "Use NetworkManager" also installs nm-applet: the Quickshell network panel replaces it.
# Its connection editor stays (the panel's "Edit" opens it), so mark it wanted before removing the applet:
# it came in as the applet's dependency, and `yay --needed` above skipped it.
if pacman -Q network-manager-applet &>/dev/null; then
    info "Removing nm-applet (replaced by the Quickshell network panel)"
    sudo pacman -D --asexplicit nm-connection-editor
    sudo pacman -Rns --noconfirm network-manager-applet
    success "nm-applet removed"
fi
