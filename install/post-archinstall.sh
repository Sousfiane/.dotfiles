#!/bin/env bash

CLONE_DIR=$(pwd)
REPO_URL="https://github.com/Sousfiane/.dotfiles"
REPO_NAME=".dotfiles"

sudo pacman -S --noconfirm --needed git

if [ -d $REPO_NAME/$REPO_NAME ]; then
    echo "Dotfiles already cloned. Skipping ..."
else
    git clone $REPO_URL
    exec "$CLONE_DIR/$REPO_NAME/install/install-all.sh"
fi
