#!/usr/bin/env bash
# The login screen: greetd with the Quickshell greeter (install/greeter), in place of sddm. Installs its files
# into /etc/greetd, makes /var/lib/qs-greeter (the theme and wallpaper it reads: the home is private), and
# then, asking first, switches the login screen from sddm to greetd.
#
# Optional, run by name: `install/install.sh greeter`. Run it again after changing install/greeter, the lock
# screen (LockFace.qml), or the monitors or keyboard in config/hypr (the greeter has its own copies). To go
# back to sddm:
#   sudo systemctl disable greetd && sudo systemctl enable sddm
#
# If the login screen ever fails to come up, another console still works (Ctrl+Alt+F2) to log in there and
# run that.

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

command -v greetd &>/dev/null || fail "greetd is missing (in packages/desktop.txt: run the packages step)"
command -v qs &>/dev/null || fail "Quickshell is missing (in packages/desktop.txt: run the packages step)"
id greeter &>/dev/null || fail "The greeter user is missing (greetd's package makes it: reinstall greetd)"

src="$DOTFILES/install/greeter"
hypr="$DOTFILES/config/hypr/config"

# ---------- the files ----------

sudo install -d -m 755 /etc/greetd/hypr /etc/greetd/quickshell
sudo install -m 644 "$src/shell.qml" /etc/greetd/quickshell/shell.qml
sudo install -m 644 "$src/LockFace.qml" /etc/greetd/quickshell/LockFace.qml   # the lock screen's, through the link
sudo install -m 644 "$src/hyprland.lua" /etc/greetd/hypr/hyprland.lua
sudo install -m 644 "$hypr/monitors.lua" /etc/greetd/hypr/monitors.lua
sudo install -m 644 "$hypr/input.lua" /etc/greetd/hypr/input.lua
sudo install -m 644 "$src/config.toml" /etc/greetd/config.toml
success "Greeter installed in /etc/greetd"

# the theme it reads: a folder the user owns and the greeter can read
sudo install -d -o "$USER" -g "$(id -gn)" -m 755 /var/lib/qs-greeter
"$HOME/.config/theme/files.sh" || warn "The theme couldn't be written for the greeter (files.sh)"
state=$(find "$HOME/.local/state/quickshell" -name wallpaper -type f 2>/dev/null | head -n 1)
wall=$(head -n 1 "$state" 2>/dev/null || true)
if [[ -f $wall ]]; then
    cp -f -- "$wall" /var/lib/qs-greeter/wallpaper
    success "Theme and wallpaper copied for the greeter"
else
    warn "No wallpaper picked yet: the greeter shows a plain background until one is"
fi

# the config greetd will run, checked before it's the only way in
Hyprland --verify-config -c /etc/greetd/hypr/hyprland.lua 2>/dev/null | grep -q "config ok" \
    || fail "The greeter's Hyprland config doesn't parse: login screen left as it is"

# ---------- the switch ----------

if systemctl is-enabled -q greetd.service 2>/dev/null; then
    success "greetd is already the login screen"
    exit 0
fi

current=$(readlink /etc/systemd/system/display-manager.service 2>/dev/null || true)
info "The login screen is ${current:+$(basename "$current")}${current:-not set}. From the next boot it would be greetd."
info "If it fails, Ctrl+Alt+F2 gives a console: log in, then sudo systemctl disable greetd && sudo systemctl enable sddm"
user "Switch the login screen to greetd? [y/N]"
read -r -n 1 key </dev/tty
echo
if [[ $key != [yY] ]]; then
    success "Login screen left as it is (the greeter is installed: run this again to switch)"
    exit 0
fi
[[ -n $current ]] && sudo systemctl disable "$(basename "$current")"
sudo systemctl enable greetd.service
success "greetd is the login screen from the next boot"
