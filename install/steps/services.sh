#!/usr/bin/env bash
# the system services the desktop relies on, enabled for the next boot (not started now: starting the
# login screen in the middle of the install would take over the screen)

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

enable() {
    local unit=$1
    if systemctl is-enabled -q "$unit" 2>/dev/null; then
        success "$unit already enabled"
    else
        sudo systemctl enable "$unit"
        success "$unit enabled"
    fi
}

enable NetworkManager.service    # the network panel
enable bluetooth.service         # the Bluetooth panel

# the login screen: only if no other one is set up, since there can be a single display manager
current=$(readlink /etc/systemd/system/display-manager.service 2>/dev/null || true)
if [[ -z $current || $current == */sddm.service ]]; then
    enable sddm.service
else
    warn "Another login screen is enabled ($(basename "$current")): sddm left alone"
fi
