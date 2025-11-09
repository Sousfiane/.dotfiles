#!/usr/bin/env bash

set -o pipefail

# Ensure DOTFILES is set
if [ -z "${DOTFILES:-}" ]; then
  echo "Error: DOTFILES environment variable is not set."
  echo "Please run this script through install-all.sh or export DOTFILES manually."
  exit 1
fi

source "$DOTFILES/install/utils/messages.sh"

if command -v yay &> /dev/null; then
    info "yay is already installed"
    exit 0
fi

info "Installing prerequisites (git, base-devel)..."
sudo pacman -S --needed --noconfirm git base-devel
success "Base packages installed"

info "Cloning yay AUR repo to /tmp..."
tmpdir=$(mktemp -d /tmp/yay-build-XXXX)
git clone https://aur.archlinux.org/yay.git "$tmpdir/yay"

info "Building yay from source..."
makepkg -si --noconfirm -C -p "$tmpdir/yay/PKGBUILD"

success "yay installed successfully"

rm -rf "$tmpdir"

