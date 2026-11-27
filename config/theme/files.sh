#!/usr/bin/env bash
# The theme for the apps that can only read their own format, written from theme.json, the fonts picked
# (~/.local/state/theme/fonts.json) and the current palette. apply.sh runs this whenever any of them changes.
# These files aren't in the dotfiles: edit theme.json, or this file.
#
#   ~/.config/hypr/hyprtoolkit.conf     hyprtoolkit apps (hyprland-dialog, the share picker, the polkit agent)
#   ~/.config/qt6ct/qt6ct.conf          Qt apps: style, fonts, icons
#   ~/.config/qt6ct/colors.conf         Qt apps: colours
#   ~/.config/vesktop/themes/palette.theme.css   Discord: the palette, over rin's Rosé Pine theme

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

# ---------- qt6ct ----------

qt6ct() {
    header ";"
    jq -r --arg home "$HOME" '
        # a Qt font: family, point size, then Qt'"'"'s defaults for the rest
        .font.appPointSize as $size
        | def qfont(family): "\"" + family + ",\($size),-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular\"";
        [
            "[Appearance]",
            "color_scheme_path=" + $home + "/.config/qt6ct/colors.conf",
            "custom_palette=true",
            "icon_theme=" + .icons,
            "standard_dialogs=default",
            "style=Fusion",
            "",
            "[Fonts]",
            "fixed=" + qfont(.font.mono),
            "general=" + qfont(.font.app // .font.ui),
            "",
            "[Interface]",
            "activate_item_on_single_click=1",
            "buttonbox_layout=0",
            "cursor_flash_time=1000",
            "dialog_buttons_have_icons=1",
            "double_click_interval=400",
            "gui_effects=@Invalid()",
            "keyboard_scheme=2",
            "menus_have_icons=true",
            "show_shortcuts_in_context_menus=true",
            "stylesheets=@Invalid()",
            "toolbutton_style=4",
            "underline_shortcut=1",
            "wheel_scroll_lines=3",
            "",
            "[Troubleshooting]",
            "force_raster_widgets=1",
            "ignored_applications=@Invalid()"
        ] | join("\n")' <<<"$theme"
}

# ---------- Qt colours ----------

# Qt's palette roles, in the order qt6ct lists them: a palette colour's name for each group, or a fixed
# #AARRGGBB. Columns: active, disabled, inactive
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

# ---------- write them ----------

status=0
write "$HOME/.config/hypr/hyprtoolkit.conf" hyprtoolkit || status=1
write "$HOME/.config/qt6ct/qt6ct.conf" qt6ct || status=1
write "$HOME/.config/qt6ct/colors.conf" qt_colors || status=1
write "$HOME/.config/vesktop/themes/palette.theme.css" discord || status=1
exit $status
