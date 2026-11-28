#!/usr/bin/env bash
# The login screen: greetd with the Quickshell greeter, in place of sddm. The greeter's files are in the home
# like the rest (config/hypr/greeter.lua, config/quickshell/greeter.qml, linked by the links step); greetd
# runs them as its `greeter` user, which this lets cross the home with an ACL (`x` only: it can't list the
# home, only reach paths it knows, and what's under them that others can read). Then it writes
# /etc/greetd/config.toml and /etc/pam.d/greetd (the login unlocks the keyring) and, asking first, switches the
# login screen from sddm to greetd.
#
# Optional, run by name: `install/install.sh greeter`. Changes to the greeter, the lock screen, the theme,
# the wallpaper, the monitors or the keyboard reach it by themselves: no need to run this again. To go back
# to sddm:
#   sudo systemctl disable greetd && sudo systemctl enable sddm
#
# If the login screen ever fails to come up, another console still works (Ctrl+Alt+F2) to log in there and
# run that.

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

command -v greetd &>/dev/null || fail "greetd is missing (in packages/desktop.txt: run the packages step)"
command -v qs &>/dev/null || fail "Quickshell is missing (in packages/desktop.txt: run the packages step)"
command -v setfacl &>/dev/null || fail "setfacl is missing (the acl package)"
id greeter &>/dev/null || fail "The greeter user is missing (greetd's package makes it: reinstall greetd)"

hypr="$HOME/.config/hypr/greeter.lua"
shell="$HOME/.config/quickshell/greeter.qml"
[[ -e $hypr && -e $shell ]] || fail "The greeter's files aren't linked in ~/.config: run the links step"

# ---------- the greeter may read the home ----------

sudo setfacl -m u:greeter:x "$HOME"
for f in "$hypr" "$shell" "$HOME/.config/theme/theme.json"; do
    sudo -u greeter test -r "$f" || fail "The greeter user still can't read ${f/#$HOME/\~}: login screen left as it is"
done
success "The greeter user may cross ~ (an ACL: it can't list it)"

# the config greetd will run, checked before it's the only way in
QS_GREETER_HOME=$HOME Hyprland --verify-config -c "$hypr" 2>/dev/null | grep -q "config ok" \
    || fail "The greeter's Hyprland config doesn't parse: login screen left as it is"

# ---------- greetd's config ----------

# What greetd runs as the login screen, as its `greeter` user: the Quickshell greeter in its small Hyprland,
# with nothing of a desktop session for the greeter user (no systemd session target, no portals). greetd runs
# the line with sh (`exec <command>`), so `env` sets the variables; output is dropped, it would print on the
# console under the screen (Hyprland keeps its own log, in /run/user/<greeter's uid>/hypr).
sudo tee /etc/greetd/config.toml >/dev/null <<EOF
# Written by ~/.dotfiles/install/steps/greeter.sh: the login screen, the Quickshell greeter in a small
# Hyprland (~/.config/hypr/greeter.lua), run as the \`greeter\` user.

[terminal]
vt = 1

[default_session]
command = "env QS_GREETER_HOME=$HOME HYPRLAND_NO_SD_TARGET=1 HYPRLAND_NO_SD_VARS=1 QT_NO_XDG_DESKTOP_PORTAL=1 start-hyprland -- -c $hypr >/dev/null 2>&1"
user = "greeter"
EOF
success "greetd's config written (/etc/greetd/config.toml)"

# greetd's PAM stack, as the package ships it plus gnome-keyring (as sddm's had it): the password typed at
# login unlocks the login keyring. The session line is skipped for the greeter's own session (greetd opens
# it through the same stack, with no password), which would only start a keyring daemon for the greeter.
sudo tee /etc/pam.d/greetd >/dev/null <<'EOF'
#%PAM-1.0
# Written by ~/.dotfiles/install/steps/greeter.sh: the package's stack plus gnome-keyring.

auth       required     pam_securetty.so
auth       requisite    pam_nologin.so
auth       include      system-local-login
-auth      optional     pam_gnome_keyring.so
account    include      system-local-login
session    include      system-local-login
session    [success=1 default=ignore] pam_succeed_if.so user = greeter quiet
-session   optional     pam_gnome_keyring.so auto_start
EOF
success "greetd's PAM stack written (/etc/pam.d/greetd: the login unlocks the keyring)"

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
