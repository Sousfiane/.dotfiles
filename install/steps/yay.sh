#!/usr/bin/env bash
# yay, the AUR helper the packages step uses: built from the AUR in a temporary folder

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

if command -v yay &>/dev/null; then
    success "yay already installed"
    exit 0
fi

info "Installing the build tools (git, base-devel)"
sudo pacman -S --needed --noconfirm git base-devel

build=$(mktemp -d)
trap 'rm -rf "$build"' EXIT

info "Building yay"
git clone --depth 1 https://aur.archlinux.org/yay.git "$build/yay"
(cd "$build/yay" && makepkg -si --noconfirm)
success "yay installed"
