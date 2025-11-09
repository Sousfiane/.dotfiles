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
    return
fi

info "Enabling multilib repository..."
sudo sed -i '/^\#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
sudo pacman -Sy --noconfirm
success "Multilib repository enabled."

# Install base packages
base_list=$PACKAGE_LIST_DIR/base.packages
info "Installing base packages"
yay -S --noconfirm --needed - < "$base_list"
success "Base Packages installed"

# Install specific packages based on HOSTNAME
if [[ $HOSTNAME == "PC" ]];then
    specific_list=$PACKAGE_LIST_DIR/desktop.packages
fi

if [[ $HOSTNAME == "macbook" ]];then
    specific_list=$PACKAGE_LIST_DIR/laptop.packages
fi

if [ -z specific_list ]; then
    info "No specific packages to install, Skipping..."
else
    yay -S --noconfirm --needed - < "$specific_list"
fi
