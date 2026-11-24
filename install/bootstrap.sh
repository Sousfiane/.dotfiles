#!/usr/bin/env bash
# The first thing to run on a fresh Arch, as your user, once archinstall is done:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/Sousfiane/.dotfiles/main/install/bootstrap.sh)
#
# Clones the dotfiles to ~/.dotfiles (or updates them if they're already there), then runs the install.
# Arguments are passed on to install.sh.

set -euo pipefail

REPO_URL="https://github.com/Sousfiane/.dotfiles"
TARGET="$HOME/.dotfiles"

sudo pacman -S --needed --noconfirm git

if [[ -d "$TARGET/.git" ]]; then
    echo "Dotfiles already in $TARGET: updating them"
    git -C "$TARGET" pull --ff-only
else
    git clone "$REPO_URL" "$TARGET"
fi

exec "$TARGET/install/install.sh" "$@"
