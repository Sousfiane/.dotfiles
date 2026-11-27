#!/usr/bin/env bash
# The theme for the apps that can only read their own format, written from theme.json, the fonts picked
# (~/.local/state/theme/fonts.json) and the current palette. apply.sh runs this whenever any of them changes.
# These files aren't in the dotfiles: edit theme.json, or this file.
#
#   ~/.config/hypr/hyprtoolkit.conf     hyprtoolkit apps (hyprland-dialog, the share picker)
#   ~/.config/hypr/hyprqt6engine.conf          Qt apps: style, fonts, icons
#   ~/.config/hypr/hyprqt6engine-colors.conf   Qt apps: colours
#   ~/.config/kdeglobals                       Qt apps: KDE's colour groups ([Colors:*] only)
#   ~/.config/vesktop/themes/palette.theme.css   Discord: the palette, over rin's Rosé Pine theme
#   /var/lib/qs-greeter/theme.json             the login screen: palette, font, user (if the folder exists)

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

fonts="$THEME_STATE/fonts.json"
jq -e 'type == "object"' "$fonts" >/dev/null 2>&1 || fonts=<(echo '{}')   # one that doesn't parse is ignored

# theme.json, the fonts picked over its own, then the palette on top (its colors, name, dark, gtk...)
theme=$(jq -s '.[0] as $t | .[1] as $f | .[2] as $p | ($t | .font += $f) + $p' "$THEME_DIR/theme.json" "$fonts" "$(theme_palette_file)")

# writes what `make` prints to `path`, in one step so an app never reads half a file. Only once it's all
# there: when `make` fails, the old file stays
write() {
    local path=$1 make=$2 tmp="$1.tmp"
    mkdir -p "$(dirname "$path")"
    if ! "$make" >"$tmp"; then
        rm -f "$tmp"
        echo "files.sh: couldn't write $path" >&2
        return 1
    fi
    mv -f "$tmp" "$path"     # a link there (into the dotfiles, from before) is replaced too, not followed
}

# the note at the top of each file, with that format's comment mark
header() {
    printf '%s Written by ~/.config/theme/files.sh from ~/.config/theme/theme.json and its palette:\n' "$1"
    printf '%s edit those, since this file is replaced on every theme change.\n\n' "$1"
}

# ---------- hyprtoolkit ----------

hyprtoolkit() {
    header "#"
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

# ---------- hyprqt6engine ----------

# Qt apps' platform theme (QT_QPA_PLATFORMTHEME=hyprqt6engine, in uwsm/env): hyprlang, like hyprtoolkit's.
# The style is Darkly (rounded, from the AUR), which takes its colours from the palette below; without it
# Qt falls back to Fusion
hyprqt6engine() {
    header "#"
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
    header ";"
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

# ---------- Discord (Vesktop) ----------

# The theme itself is rin's Rosé Pine, an online theme in Vesktop (its link in Settings > Themes, so it
# stays up to date; Discord's own theme set to Ash, as it asks). It reads its colours from the 15 Rosé Pine
# variables, all set in one :root block: this file sets them again from the palette. :root:root wins
# whichever of the two Vesktop loads first. Vesktop watches its themes folder, so a palette switch shows at
# once; apply.sh makes sure this one is enabled
discord() {
    # Vesktop names the theme from this first comment
    printf '/**\n * @name System palette\n * @description The current palette from ~/.config/theme, over rin'"'"'s Rosé Pine.\n */\n\n'
    header "/*" | sed 's|.\+|& */|'
    jq -r '
        ["base", "surface", "overlay", "muted", "subtle", "text", "love", "gold", "rose", "pine", "foam",
         "iris", "highlightLow", "highlightMed", "highlightHigh"] as $names
        | ":root:root {", ($names[] as $n | "    --\($n): \(.colors[$n]);"), "}"' <<<"$theme"
}

# ---------- the login screen ----------

# The greeter runs as another user and can't read the home (it's private), so it reads this copy in
# /var/lib/qs-greeter, a folder the user owns (install/steps/greeter.sh makes it). The wallpaper is copied
# there by Quickshell's wallpaper service
GREETER_DIR=${QS_GREETER_DIR:-/var/lib/qs-greeter}
greeter() {
    jq --arg user "$USER" '{
        user: $user,
        colors: .colors,
        font: (.font.ui),
        fontSize: (.font.uiPixelSize),
        radius: (.radius.large),
        panelAlpha: (.opacity.panel)
    }' <<<"$theme"
}

# ---------- write them ----------

status=0
write "$HOME/.config/hypr/hyprtoolkit.conf" hyprtoolkit || status=1
write "$HOME/.config/hypr/hyprqt6engine.conf" hyprqt6engine || status=1
write "$HOME/.config/hypr/hyprqt6engine-colors.conf" qt_colors || status=1
write "$HOME/.config/kdeglobals" kdeglobals || status=1
write "$HOME/.config/vesktop/themes/palette.theme.css" discord || status=1
if [[ -w $GREETER_DIR ]]; then
    write "$GREETER_DIR/theme.json" greeter || status=1
fi
exit $status
