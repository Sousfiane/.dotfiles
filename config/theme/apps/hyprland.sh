#!/usr/bin/env bash
# Hyprland, and the hyprtoolkit apps (hyprland-dialog, the share picker): hyprtoolkit can only read its
# own format, so ~/.config/hypr/hyprtoolkit.conf is written from the theme; then Hyprland reloads its
# config for its own colours (config/hypr/config/theme.lua reads the theme itself).

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

file=$(theme_current)            # the merged theme: theme.json, the fonts picked and the palette
theme=$(<"$file")
status=0

# ---------- hyprtoolkit ----------

hyprtoolkit() {
    theme_header "#"
    jq -r '
        def argb(name): "0xFF" + (.colors[name] | .[1:]);
        .font.appPointSize as $size
        | [
            # mapped the way quickshell'"'"'s Theme.qml uses them
            "background = " + argb("base"),            # Theme.bg (bar, dropdowns)
            "base = " + argb("overlay"),               # Theme.surface (rows, buttons, inputs)
            "alternate_base = " + argb("highlightMed"),  # hovered / unfocused input border
            "text = " + argb("text"),
            "bright_text = " + argb("rose"),
            "link_text = " + argb("foam"),
            "accent = " + argb("iris"),                # Theme.accent / Theme.border
            "accent_secondary = " + argb("foam"),
            "",
            "font_family = " + (.font.app // .font.ui),
            "font_family_monospace = " + .font.mono,
            "font_size = \($size)",
            "small_font_size = \($size - 1)",
            "h3_size = \($size + 1)",
            "h2_size = \($size + 2)",
            "h1_size = \($size + 4)",
            "",
            "icon_theme = " + .icons,
            "rounding_small = \(.radius.medium)",
            "rounding_large = \(.radius.large)"
        ] | join("\n")' <<<"$theme"
}

theme_write "$HOME/.config/hypr/hyprtoolkit.conf" hyprtoolkit || status=1

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl reload >/dev/null
fi

exit $status
