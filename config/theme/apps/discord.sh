#!/usr/bin/env bash
# Discord (Vesktop): rin's Rosé Pine as an online theme (its link, so it stays up to date), with the
# palette over it in ~/.config/vesktop/themes/palette.theme.css, which Vesktop reloads by itself. Both are
# put in Vesktop's settings when missing, only while it's closed: it keeps its settings in memory and would
# save over the change.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

file=$(theme_current)            # the merged theme: theme.json, the fonts picked and the palette
theme=$(<"$file")
status=0

# ---------- Discord (Vesktop) ----------

# The theme itself is rin's Rosé Pine, an online theme in Vesktop (its link in Settings > Themes, so it
# stays up to date; Discord's own theme set to Ash, as it asks). It reads its colours from the 15 Rosé Pine
# variables, all set in one :root block: this file sets them again from the palette. :root:root wins
# whichever of the two Vesktop loads first. Vesktop watches its themes folder, so a palette switch shows at
# once; apply.sh makes sure this one is enabled
discord() {
    # Vesktop names the theme from this first comment
    printf '/**\n * @name System palette\n * @description The current palette from ~/.config/theme, over rin'"'"'s Rosé Pine.\n */\n\n'
    theme_header "/*" | sed 's|.\+|& */|'
    jq -r '
        ["base", "surface", "overlay", "muted", "subtle", "text", "love", "gold", "rose", "pine", "foam",
         "iris", "highlightLow", "highlightMed", "highlightHigh"] as $names
        | ":root:root {", ($names[] as $n | "    --\($n): \(.colors[$n]);"), "}"' <<<"$theme"
}

theme_write "$HOME/.config/vesktop/themes/palette.theme.css" discord || status=1

vesktop="$HOME/.config/vesktop/settings/settings.json"
rin=https://raw.githubusercontent.com/baconeko/rose-pine-discord/refs/heads/main/dist/rin-rose-pine.theme.css
if [[ -f $vesktop ]] && command -v jq >/dev/null && ! pgrep -x vesktop >/dev/null &&
    ! jq -e --arg rin "$rin" '(.themeLinks // [] | index($rin)) and (.enabledThemes // [] | index("palette.theme.css"))' \
        "$vesktop" >/dev/null 2>&1; then
    jq --arg rin "$rin" '
        .themeLinks = ((.themeLinks // []) - [$rin] + [$rin])
        | .enabledThemes = ((.enabledThemes // []) - ["palette.theme.css"] + ["palette.theme.css"])' \
        "$vesktop" >"$vesktop.tmp" && mv -f "$vesktop.tmp" "$vesktop" || rm -f "$vesktop.tmp"
fi

exit $status
