#!/usr/bin/env bash
# tmux's colours and status bar, from ~/.config/theme/theme.json and the palette it names (config/theme in
# the dotfiles), which quickshell, Hyprland, kitty and Neovim read too. tmux.conf runs this with
# run-shell, so it applies on start and whenever the config is sourced again.
#
#   left:   session name (love while the prefix is pressed)
#   middle: windows, "number  name", iris, the current one gold
#   right:  current folder

source "$HOME/.config/theme/lib.sh"

if ! command -v jq >/dev/null; then
    tmux display-message "tmux theme: needs jq"
    exit 0
fi

# the colours come from the merged theme (the current palette's)
file=$(theme_current)

declare -A c
while IFS=$'\t' read -r name value; do
    c[$name]=$value
done < <(jq -r '.colors // {} | to_entries[] | "\(.key)\t\(.value)"' "$file" 2>/dev/null)

if [[ -z ${c[base]} ]]; then
    tmux display-message "tmux theme: can't read $file"
    exit 0
fi

# Nerd Font icons
session_icon=$''
window_icon=$''
folder_icon=$''

options=(
    status on
    status-style "fg=${c[pine]},bg=${c[base]}"
    status-left-length 200
    status-right-length 200
    status-left "#[fg=#{?client_prefix,${c[love]},${c[text]}}]$session_icon #[fg=${c[text]}]#S#[fg=${c[text]}]  "
    status-right "#[fg=${c[subtle]}]$folder_icon #[fg=${c[rose]}]#{b:pane_current_path}"

    message-style "fg=${c[muted]},bg=${c[base]}"
    message-command-style "fg=${c[base]},bg=${c[gold]}"

    pane-border-style "fg=${c[highlightHigh]}"
    pane-active-border-style "fg=${c[gold]}"
    display-panes-active-colour "${c[text]}"
    display-panes-colour "${c[gold]}"

    window-status-style "fg=${c[iris]},bg=${c[base]}"
    window-status-activity-style "fg=${c[base]},bg=${c[rose]}"
    window-status-current-style "fg=${c[gold]},bg=${c[base]}"
    window-status-format "#[fg=${c[iris]}]#I#[fg=${c[iris]},] $window_icon #[fg=${c[iris]}]#W"
    window-status-current-format "#I#[fg=${c[gold]},bg=] $window_icon #[fg=${c[gold]},bg=]#W"
    window-status-separator " "

    clock-mode-colour "${c[love]}"
    mode-style "bg=${c[highlightMed]}"
)

# all in one tmux call
args=()
for ((i = 0; i < ${#options[@]}; i += 2)); do
    args+=(set-option -gq "${options[i]}" "${options[i + 1]}" ";")
done
tmux "${args[@]}"
