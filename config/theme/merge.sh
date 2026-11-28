#!/usr/bin/env bash
# The theme as every app reads it: ~/.local/state/theme/current.json, theme.json with the fonts picked over
# its own and the current palette on top (its colors, name, dark, gtk...), "palette" being that palette's
# file name. The one place that works out which palette is current; the apps only read the result.
#
# apply.sh runs this first on every theme change (Quickshell runs apply.sh when a theme file changes, the
# `theme` command when Quickshell isn't running), and an app that finds no current.json yet runs it itself.
# Also creates the state files when missing, so they can be watched: the palette's name (theme.json's
# default) and the fonts picked (none).
#
# The file is written only when it changes, in one step (a new file renamed over the old), so an app
# watching it never sees half a file or a change that isn't one. When a file doesn't parse (a typo while
# editing), the last good current.json stays and this fails.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

out="$THEME_STATE/current.json"
mkdir -p "$THEME_STATE"
[[ -s $THEME_STATE/palette ]] || jq -r '.palette // "rose-pine"' "$THEME_DIR/theme.json" >"$THEME_STATE/palette"
[[ -s $THEME_STATE/fonts.json ]] || echo '{}' >"$THEME_STATE/fonts.json"

fonts="$THEME_STATE/fonts.json"
jq -e 'type == "object"' "$fonts" >/dev/null 2>&1 || fonts=<(echo '{}')   # one that doesn't parse is ignored

name=$(theme_palette_name)
merged=$(jq -s --arg name "$name" '.[0] as $t | .[1] as $f | .[2] as $p
    | ($t | .font += $f) + $p + {palette: $name}' \
    "$THEME_DIR/theme.json" "$fonts" "$THEME_DIR/palettes/$name.json") || {
    echo "merge.sh: theme.json or palettes/$name.json doesn't parse: current.json left as it was" >&2
    exit 1
}

[[ -f $out && $(<"$out") == "$merged" ]] && exit 0
printf '%s\n' "$merged" >"$out.tmp"
mv -f "$out.tmp" "$out"
