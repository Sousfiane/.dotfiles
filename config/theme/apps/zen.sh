#!/usr/bin/env bash
# Zen: its userChrome.css, userContent.css and user.js in each profile, written from the theme (Zen can
# only read its own format), and Dark Reader's colours (darkreader.py). Zen reads them only as it starts: if
# it's open and its colours changed, it's closed (TERM to its main process: a normal quit, the session saved)
# and opened again, its tabs restored and its windows where they were (reopen.sh). Dark Reader's colours are
# written in between, as it saves over them while Zen runs; when Zen is closed, at once.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

file=$(theme_current)            # the merged theme: theme.json, the fonts picked and the palette
theme=$(<"$file")
status=0

# its colours as they were, to tell whether they change
zen_colors() {
    cat "$HOME"/.config/zen/*/chrome/userChrome.css "$HOME"/.zen/*/chrome/userChrome.css 2>/dev/null | md5sum
}
zen_before=$(zen_colors)

# ---------- Zen browser ----------

# Zen's own colours are CSS variables (zen-theme.css in its omni.ja), most derived from one accent: they're
# all set from the palette in userChrome.css, a user sheet, so its !important wins over Zen's and over the
# workspace gradient Zen sets on the window itself. Its pages (new tab, blank) in userContent.css, and the
# prefs in user.js: the stylesheets switched on, the window and websites dark or light with the palette,
# the accent. Zen reads all three only as it starts: a switch shows the next time it opens.
zen_chrome() {
    theme_header "/*" | sed 's|.\+|& */|'
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
    theme_header "/*" | sed 's|.\+|& */|'
    jq -r '.colors as $c | "/* the browser'"'"'s own empty pages: no white flash between pages, and the new tab in the palette */
@-moz-document url(\"about:blank\"), url(\"about:newtab\"), url(\"about:home\"), url(\"about:privatebrowsing\") {
    html, body {
        background-color: \($c.base) !important;
        color: \($c.text) !important;
    }
}"' <<<"$theme"
}

zen_prefs() {
    theme_header "//"
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
    [[ ! -e $1 ]] || grep -q "Written by ~/.config/theme/" "$1"
}

zen() {
    local profile file status=0
    while IFS= read -r profile; do
        for file in chrome/userChrome.css:zen_chrome chrome/userContent.css:zen_content user.js:zen_prefs; do
            if ours "$profile/${file%%:*}"; then
                theme_write "$profile/${file%%:*}" "${file##*:}" || status=1
            else
                echo "zen.sh: $profile/${file%%:*} isn't one of these files: left as it is" >&2
            fi
        done
    done < <(zen_profiles)
    return $status
}

zen || status=1

darkreader=(python3 -I "$(dirname "${BASH_SOURCE[0]}")/darkreader.py" "$file")
if main=$(pgrep -o -x zen-bin); then
    if [[ $(zen_colors) != "$zen_before" ]]; then
        setsid -f bash -c '
            "$2" save zen
            kill -TERM "$1"
            for _ in $(seq 75); do
                if ! kill -0 "$1" 2>/dev/null; then
                    "${@:3}"
                    exec "$2" start zen "uwsm-app -- zen.desktop"
                fi
                sleep 0.2
            done' _ "$main" "$(dirname "${BASH_SOURCE[0]}")/../reopen.sh" "${darkreader[@]}" >/dev/null 2>&1
    fi
elif command -v python3 >/dev/null; then
    "${darkreader[@]}"
fi

exit $status
