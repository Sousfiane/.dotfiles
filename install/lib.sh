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

# the GPUs' makers, one per line (nvidia, amd, intel): the display controllers (PCI class 0x03) in /sys, so
# it needs nothing installed. A laptop with an Intel and an NVIDIA GPU gives both; a VM may give none.
gpu_vendors() {
    local dev vendor
    for dev in /sys/bus/pci/devices/*; do
        [[ $(<"$dev/class") == 0x03* ]] || continue
        vendor=$(<"$dev/vendor")
        case $vendor in
            0x10de) echo nvidia ;;
            0x1002) echo amd ;;
            0x8086) echo intel ;;
        esac
    done | sort -u
}

# everything the install puts on the machine: the GPUs' driver lists (packages/gpu) included
wanted_packages() {
    local vendor
    read_list desktop.txt
    read_list apps.txt
    for vendor in $(gpu_vendors); do
        read_list "gpu/$vendor.txt"
    done
}

is_installed() {
    pacman -Q "$1" &>/dev/null
}
