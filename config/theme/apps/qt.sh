#!/usr/bin/env bash
# Qt apps: hyprqt6engine (their platform theme, QT_QPA_PLATFORMTHEME in uwsm/env) and the Darkly style
# can only read their own formats, so they're written from the theme:
#   ~/.config/hypr/hyprqt6engine.conf          style, fonts, icons
#   ~/.config/hypr/hyprqt6engine-colors.conf   colours
#   ~/.config/kdeglobals                       KDE's colour groups ([Colors:*] only), which Darkly reads too
# Qt apps read them as they start.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

file=$(theme_current)            # the merged theme: theme.json, the fonts picked and the palette
theme=$(<"$file")
status=0

# ---------- hyprqt6engine ----------

# Qt apps' platform theme (QT_QPA_PLATFORMTHEME=hyprqt6engine, in uwsm/env): hyprlang, like hyprtoolkit's.
# The style is Darkly (rounded, from the AUR), which takes its colours from the palette below; without it
# Qt falls back to Fusion
hyprqt6engine() {
    theme_header "#"
    jq -r --arg colors "$HOME/.config/hypr/hyprqt6engine-colors.conf" '
        .font.appPointSize as $size
        | [
            "theme {",
            "    style = Darkly",
            "    color_scheme = " + $colors,
            "    icon_theme = " + .icons,
            "    font = " + (.font.app // .font.ui),
            "    font_size = \($size)",
            "    font_fixed = " + .font.mono,
            "    font_fixed_size = \($size)",
            "}",
            "",
            "misc {",
            "    single_click_activate = true",
            "    menus_have_icons = true",
            "    shortcuts_for_context_menus = true",
            "}"
        ] | join("\n")' <<<"$theme"
}

# ---------- Qt colours ----------

# Qt's palette roles, in qt6ct's colour scheme format (hyprqt6engine reads it too): a palette colour's name
# for each group, or a fixed #AARRGGBB. Columns: active, disabled, inactive
qt_colors() {
    theme_header ";"
    echo "[ColorScheme]"
    jq -r '
        .colors as $c
        | def role(name; a; d; i): {name: name, active: a, disabled: d, inactive: i};
        [
            role("WindowText";      "text";          "rose";          "text"),
            role("Button";          "overlay";       "surface";       "overlay"),
            role("Light";           "highlightHigh"; "highlightHigh"; "highlightHigh"),
            role("Midlight";        "highlightMed";  "highlightMed";  "highlightMed"),
            role("Dark";            "highlightLow";  "highlightLow";  "highlightLow"),
            role("Mid";             "overlay";       "overlay";       "overlay"),
            role("Text";            "muted";         "muted";         "muted"),
            role("BrightText";      "love";          "love";          "love"),
            role("ButtonText";      "rose";          "rose";          "rose"),
            role("Base";            "overlay";       "overlay";       "overlay"),
            role("Window";          "base";          "base";          "base"),
            role("Shadow";          "overlay";       "overlay";       "overlay"),
            role("Highlight";       "highlightHigh"; "highlightMed";  "highlightMed"),
            role("HighlightedText"; "gold";          "highlightHigh"; "rose"),
            role("Link";            "foam";          "subtle";        "pine"),
            role("LinkVisited";     "iris";          "highlightHigh"; "muted"),
            role("AlternateBase";   "surface";       "surface";       "surface"),
            role("NoRole";          "#ff000000";     "#ff000000";     "#ff000000"),
            role("ToolTipBase";     "highlightLow";  "highlightLow";  "highlightLow"),
            role("ToolTipText";     "subtle";        "foam";          "iris"),
            role("PlaceholderText"; "#809e9e9e";     "#809e9e9e";     "#809e9e9e")
        ] as $roles
        | ["active", "disabled", "inactive"][] as $group
        | $group + "_colors=" + ($roles | map(.[$group] | if startswith("#") then . else "#ff" + ($c[.] | .[1:]) end) | join(", "))
    ' <<<"$theme"
}

# ---------- KDE colours ----------

# Darkly (and KDE apps) take some colours from KDE's colour groups in kdeglobals rather than from the Qt
# palette: the menu bar from Header, text fields from View... Without them they fall back to KDE's light
# defaults (dark menu bar text, white fields). The same palette names as qt_colors, for each group.
# kdeglobals also holds the KDE apps' own settings (the file dialog's): those stay, only [Colors:*] is replaced
kdeglobals() {
    local file="$HOME/.config/kdeglobals"
    # the file as the apps left it, without its colour groups or the blank lines they leave at the end
    if [[ -f $file ]]; then
        awk '/^\[/ { skip = /^\[Colors:/ }
             skip { next }
             /^[[:space:]]*$/ { blanks++; next }
             { while (blanks) { print ""; blanks-- } print }' "$file"
        echo
    fi
    jq -r '
        # "#rrggbb" to KDE'"'"'s "r,g,b"
        def hex: ascii_downcase | explode | reduce .[] as $d (0; . * 16 + (if $d >= 97 then $d - 87 else $d - 48 end));
        def rgb(name): .colors[name] | [.[1:3], .[3:5], .[5:7]] | map(hex | tostring) | join(",");
        . as $t
        | def group(name; bg; alt; fg; inactive):
            "[Colors:" + name + "]",
            "BackgroundNormal=" + ($t | rgb(bg)),
            "BackgroundAlternate=" + ($t | rgb(alt)),
            "ForegroundNormal=" + ($t | rgb(fg)),
            "ForegroundInactive=" + ($t | rgb(inactive)),
            "ForegroundActive=" + ($t | rgb("rose")),
            "ForegroundLink=" + ($t | rgb("foam")),
            "ForegroundVisited=" + ($t | rgb("iris")),
            "ForegroundNegative=" + ($t | rgb("love")),
            "ForegroundNeutral=" + ($t | rgb("gold")),
            "ForegroundPositive=" + ($t | rgb("pine")),
            "DecorationFocus=" + ($t | rgb("iris")),
            "DecorationHover=" + ($t | rgb("highlightHigh")),
            "";
        group("Window";          "base";          "surface";      "text";   "subtle"),
        group("View";            "overlay";       "surface";      "text";   "subtle"),
        group("Button";          "overlay";       "surface";      "rose";   "subtle"),
        group("Selection";       "highlightHigh"; "highlightMed"; "gold";   "subtle"),
        group("Tooltip";         "highlightLow";  "surface";      "subtle"; "muted"),
        group("Complementary";   "base";          "surface";      "text";   "subtle"),
        group("Header";          "base";          "surface";      "text";   "subtle"),
        group("Header][Inactive"; "base";         "surface";      "text";   "subtle")
    ' <<<"$theme"
}

theme_write "$HOME/.config/hypr/hyprqt6engine.conf" hyprqt6engine || status=1
theme_write "$HOME/.config/hypr/hyprqt6engine-colors.conf" qt_colors || status=1
theme_write "$HOME/.config/kdeglobals" kdeglobals || status=1

exit $status
