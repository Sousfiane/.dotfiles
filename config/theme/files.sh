#!/usr/bin/env bash
# The theme for the apps that can only read their own format, written from the merged theme
# (~/.local/state/theme/current.json, merge.sh). apply.sh runs this whenever it changes.
# These files aren't in the dotfiles: edit theme.json, or this file.
#
#   ~/.config/hypr/hyprtoolkit.conf     hyprtoolkit apps (hyprland-dialog, the share picker)
#   ~/.config/hypr/hyprqt6engine.conf          Qt apps: style, fonts, icons
#   ~/.config/hypr/hyprqt6engine-colors.conf   Qt apps: colours
#   ~/.config/kdeglobals                       Qt apps: KDE's colour groups ([Colors:*] only)
#   ~/.config/vesktop/themes/palette.theme.css   Discord: the palette, over rin's Rosé Pine theme
#   <each Zen profile>/chrome/userChrome.css, chrome/userContent.css, user.js   Zen browser

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# theme.json, the fonts picked over its own, then the palette on top (its colors, name, dark, gtk...)
theme=$(<"$(theme_current)")

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

# ---------- Zen browser ----------

# Zen's own colours are CSS variables (zen-theme.css in its omni.ja), most derived from one accent: they're
# all set from the palette in userChrome.css, a user sheet, so its !important wins over Zen's and over the
# workspace gradient Zen sets on the window itself. Its pages (new tab, blank) in userContent.css, and the
# prefs in user.js: the stylesheets switched on, the window and websites dark or light with the palette,
# the accent. Zen reads all three only as it starts: a switch shows the next time it opens.
zen_chrome() {
    header "/*" | sed 's|.\+|& */|'
    jq -r '.colors as $c | "/* the window: the background Zen draws a workspace gradient on, and the text over it. On every element,
   since Zen sets them on several of its own */
:root, :root * {
    --zen-main-browser-background: \($c.base) !important;
    --zen-main-browser-background-toolbar: \($c.base) !important;
    --toolbox-textcolor: \($c.text) !important;
    --toolbox-textcolor-inactive: \($c.subtle) !important;
}

:root {
    --zen-primary-color: \($c.iris) !important;
    --zen-branding-bg: \($c.base) !important;
    --zen-branding-bg-reverse: \($c.text) !important;
    --zen-colors-primary: \($c.overlay) !important;
    --zen-colors-secondary: \($c.highlightMed) !important;
    --zen-colors-tertiary: \($c.surface) !important;
    --zen-colors-hover-bg: \($c.highlightLow) !important;
    --zen-colors-primary-foreground: \($c.text) !important;
    --zen-colors-border: \($c.highlightMed) !important;
    --zen-colors-border-contrast: \($c.highlightLow) !important;
    --zen-colors-input-bg: \($c.overlay) !important;
    --zen-dialog-background: \($c.surface) !important;
    --zen-urlbar-background: \($c.surface) !important;

    --toolbar-color: \($c.text) !important;
    --toolbar-field-color: \($c.text) !important;
    --toolbar-field-background-color: \($c.surface) !important;
    --toolbar-field-focus-color: \($c.text) !important;
    --toolbar-field-focus-background-color: \($c.overlay) !important;
    --urlbarView-highlight-background: \($c.overlay) !important;
    --urlbarView-highlight-color: \($c.text) !important;
    --arrowpanel-background: \($c.surface) !important;
    --arrowpanel-color: \($c.text) !important;
    --arrowpanel-border-color: \($c.highlightMed) !important;
    --panel-separator-color: \($c.highlightMed) !important;
    --tab-selected-bgcolor: \($c.overlay) !important;
    --tab-selected-textcolor: \($c.text) !important;
    --tab-hover-background-color: \($c.highlightLow) !important;
    --toolbarbutton-hover-background: \($c.highlightLow) !important;
    --toolbarbutton-active-background: \($c.highlightMed) !important;
    --button-hover-bgcolor: \($c.highlightLow) !important;
    --focus-outline-color: \($c.iris) !important;
    --sidebar-background-color: \($c.base) !important;
    --sidebar-text-color: \($c.text) !important;
}

::selection {
    background-color: \($c.highlightMed) !important;
    color: \($c.text) !important;
}"' <<<"$theme"
}

zen_content() {
    header "/*" | sed 's|.\+|& */|'
    jq -r '.colors as $c | "/* the browser'"'"'s own empty pages: no white flash between pages, and the new tab in the palette */
@-moz-document url(\"about:blank\"), url(\"about:newtab\"), url(\"about:home\"), url(\"about:privatebrowsing\") {
    html, body {
        background-color: \($c.base) !important;
        color: \($c.text) !important;
    }
}"' <<<"$theme"
}

zen_prefs() {
    header "//"
    jq -r '
        (if .dark then 0 else 1 end) as $scheme
        | "user_pref(\"toolkit.legacyUserProfileCustomizations.stylesheets\", true);",
          "user_pref(\"zen.view.window.scheme\", \($scheme));                           // 0 dark, 1 light",
          "user_pref(\"layout.css.prefers-color-scheme.content-override\", \($scheme));  // websites the same",
          "user_pref(\"zen.theme.accent-color\", \"\(.colors.iris)\");",
          "user_pref(\"browser.display.background_color.dark\", \"\(.colors.base)\");    // before a page draws"
    ' <<<"$theme"
}

# the profiles Zen uses: each one listed in its profiles.ini that has been opened (it has a prefs.js)
zen_profiles() {
    local root ini line
    for root in "$HOME/.config/zen" "$HOME/.zen"; do
        ini="$root/profiles.ini"
        [[ -r $ini ]] || continue
        while IFS= read -r line; do
            [[ $line == Path=* ]] || continue
            line=${line#Path=}
            [[ $line == /* ]] || line="$root/$line"
            [[ -f $line/prefs.js ]] && printf '%s\n' "$line"
        done <"$ini"
    done | sort -u
}

# a file written here, or none yet: one the user made themselves is never replaced
ours() {
    [[ ! -e $1 ]] || grep -q "Written by ~/.config/theme/files.sh" "$1"
}

zen() {
    local profile file status=0
    while IFS= read -r profile; do
        for file in chrome/userChrome.css:zen_chrome chrome/userContent.css:zen_content user.js:zen_prefs; do
            if ours "$profile/${file%%:*}"; then
                write "$profile/${file%%:*}" "${file##*:}" || status=1
            else
                echo "files.sh: $profile/${file%%:*} isn't one of these files: left as it is" >&2
            fi
        done
    done < <(zen_profiles)
    return $status
}

# ---------- write them ----------

status=0
write "$HOME/.config/hypr/hyprtoolkit.conf" hyprtoolkit || status=1
write "$HOME/.config/hypr/hyprqt6engine.conf" hyprqt6engine || status=1
write "$HOME/.config/hypr/hyprqt6engine-colors.conf" qt_colors || status=1
write "$HOME/.config/kdeglobals" kdeglobals || status=1
write "$HOME/.config/vesktop/themes/palette.theme.css" discord || status=1
zen || status=1
exit $status
