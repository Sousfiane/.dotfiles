#!/usr/bin/env bash

set -euo pipefail

# Ensure DOTFILES is set
if [ -z "${DOTFILES:-}" ]; then
  echo "Error: DOTFILES environment variable is not set."
  echo "Please run this script through install-all.sh or export DOTFILES manually."
  exit 1
fi

source "$DOTFILES/install/utils/messages.sh"

info "Changing shell to zsh..."
chsh -s $(which zsh)
success "Shell changed successfully."
