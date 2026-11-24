# shellcheck shell=bash
# Sourced by install.sh and by every step: strict mode, paths, messages, package helpers.

set -euo pipefail

# the repo, found from this file. It must be ~/.dotfiles: configs refer to it there (install.sh checks)
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES
INSTALL_DIR="$DOTFILES/install"
PACKAGES_DIR="$INSTALL_DIR/packages"

# ---------- messages ----------

info() {
    printf "\r  [ \033[00;34m..\033[0m ] %b\n" "$1"
}

user() {
    printf "\r  [ \033[0;33m??\033[0m ] %b\n" "$1"
}

success() {
    printf "\r\033[2K  [ \033[00;32mOK\033[0m ] %b\n" "$1"
}

warn() {
    printf "\r\033[2K  [\033[0;33mWARN\033[0m] %b\n" "$1"
}

fail() {
    printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %b\n\n" "$1"
    exit 1
}

# a step's title
title() {
    printf "\n\033[1m==> %s\033[0m\n" "$1"
}

# ---------- packages ----------

# a package list: one name per line; "#" starts a comment, blank lines are ignored
read_list() {
    sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$PACKAGES_DIR/$1"
}

# everything the install puts on the machine
wanted_packages() {
    read_list desktop.txt
    read_list apps.txt
}

is_installed() {
    pacman -Q "$1" &>/dev/null
}
