#!/usr/bin/env bash
# the packages: everything in desktop.txt and apps.txt, the driver for each GPU found (gpu/), then out with what
# remove.txt names

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

mapfile -t wanted < <(wanted_packages)

gpus=$(gpu_vendors | paste -sd " ")
if [[ -n $gpus ]]; then
    info "GPU: $gpus (its driver from packages/gpu)"
else
    warn "No NVIDIA, AMD or Intel GPU found: no graphics driver installed (a VM uses Mesa, which comes as a dependency)"
fi

info "Installing ${#wanted[@]} packages (already installed ones are skipped)"
yay -S --needed --noconfirm "${wanted[@]}"
success "Packages installed"

# What came in as a dependency (of archinstall's nm-applet, say) and is listed here is wanted for itself:
# mark it so. `--needed` above skipped it, and the removals below would otherwise take it along.
sudo pacman -D --asexplicit "${wanted[@]}" >/dev/null

mapfile -t remove < <(read_list remove.txt | while read -r p; do
    if is_installed "$p"; then echo "$p"; fi
done)

if [[ ${#remove[@]} -eq 0 ]]; then
    success "Nothing to remove"
else
    info "Removing what the desktop replaces: ${remove[*]}"
    sudo pacman -Rns --noconfirm "${remove[@]}"
    success "Removed"
fi
