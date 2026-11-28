#!/usr/bin/env bash
# the services the desktop relies on, enabled for the next boot or login (not started now: starting the
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

# the session's own daemons, as user services: uwsm starts them with the session (graphical-session.target),
# systemd restarts them if they crash, and they stop when it ends
enable_user() {
    local unit=$1
    if systemctl --user is-enabled -q "$unit" 2>/dev/null; then
        success "$unit already enabled"
    else
        systemctl --user enable "$unit"
        success "$unit enabled"
    fi
}

enable_user hypridle.service           # screens off when idle

# Quickshell, from its unit in the repo (install/units): `enable` with a path links it in, then enables it
shell_unit="$DOTFILES/install/units/quickshell.service"
if systemctl --user is-enabled -q quickshell.service 2>/dev/null; then
    success "quickshell.service already enabled"
else
    systemctl --user enable "$shell_unit"
    success "quickshell.service enabled (restarted if it crashes)"
fi

# the theme's watcher, from its units in the repo: theme.path sees a theme file change and starts
# theme.service, which brings every app up to date (config/theme/apply.sh). The service is only linked in:
# the path starts it
if systemctl --user is-enabled -q theme.path 2>/dev/null; then
    success "theme.path already enabled"
else
    systemctl --user link "$DOTFILES/install/units/theme.service"
    systemctl --user enable "$DOTFILES/install/units/theme.path"
    success "theme.path enabled (a theme change reaches every app)"
fi

# Quickshell is the polkit agent now, and only one can register: the old one goes
if systemctl --user is-enabled -q hyprpolkitagent.service 2>/dev/null; then
    systemctl --user disable --now hyprpolkitagent.service
    success "hyprpolkitagent.service disabled (Quickshell asks for passwords now)"
fi

# the login screen: only if no other one is set up, since there can be a single display manager
current=$(readlink /etc/systemd/system/display-manager.service 2>/dev/null || true)
if [[ -z $current || $current == */sddm.service ]]; then
    enable sddm.service
else
    warn "Another login screen is enabled ($(basename "$current")): sddm left alone"
fi
