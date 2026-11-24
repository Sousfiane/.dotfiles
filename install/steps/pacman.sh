#!/usr/bin/env bash
# pacman itself: the multilib repo (Steam), then a full upgrade, so every package installed afterwards
# matches the rest of the system (never -Sy alone: that's a partial upgrade)

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

if grep -q "^\[multilib\]" /etc/pacman.conf; then
    success "multilib already enabled"
else
    info "Enabling multilib"
    sudo sed -i '/^#\[multilib\]/,/Include/s/^#//' /etc/pacman.conf
    success "multilib enabled"
fi

info "Upgrading the system"
sudo pacman -Syu --noconfirm
success "System up to date"
