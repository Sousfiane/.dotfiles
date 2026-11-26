#!/usr/bin/env bash
# Hyprland's plugins, through hyprpm: hyprbars (the title bars, config/hypr/config/plugins.lua) and the CS2
# fix. hyprpm builds them against the running Hyprland, so this needs the desktop: autostart.lua opens a
# terminal running it at the first login, when they aren't set up yet.
#
# Optional, by name: `install/install.sh plugins`. Running it again brings them up to date with Hyprland
# (hyprpm update), which hyprpm also asks for itself after a Hyprland upgrade. hyprpm asks for sudo to write
# its headers and plugins to /var/cache/hyprpm.

source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

REPO="https://github.com/hyprwm/hyprland-plugins"
PLUGINS=(hyprbars csgo-vulkan-fix)
STATE="/var/cache/hyprpm/$USER/hyprland-plugins/state.toml"     # hyprpm's own record of that repository

command -v hyprpm &>/dev/null || fail "hyprpm isn't installed (it's in packages/desktop.txt: run the packages step)"
[[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || fail "Run this from a terminal in Hyprland: hyprpm builds the plugins for the running Hyprland."

# the headers of the running Hyprland, and the plugins already there rebuilt for them
info "Updating hyprpm (Hyprland's headers, the plugins already installed)"
hyprpm update

if [[ -f $STATE ]]; then
    success "hyprland-plugins already added"
else
    info "Adding hyprland-plugins (built now: a few minutes)"
    # hyprpm asks whether to trust the repository: yes, it's the one this config uses (fed through < <(),
    # since `yes | hyprpm` would fail under pipefail when hyprpm closes the pipe)
    hyprpm add "$REPO" < <(yes)
    success "hyprland-plugins added"
fi

# enabled = true under the plugin's [section] in hyprpm's state
is_enabled() {
    awk -v p="[$1]" '$0 == p {s = 1; next} /^\[/ {s = 0} s && /^enabled *= *true/ {found = 1} END {exit !found}' "$STATE"
}

for p in "${PLUGINS[@]}"; do
    if is_enabled "$p"; then
        success "$p already enabled"
    else
        hyprpm enable "$p"
        success "$p enabled"
    fi
done

hyprpm reload -n
success "Plugins loaded"
