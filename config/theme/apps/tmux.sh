#!/usr/bin/env bash
# tmux: it reads the theme itself (config/tmux/theme.sh, which also lays out the status bar) when its config
# is sourced, so a running server sources it again.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

file=$(theme_current)            # the merged theme: theme.json, the fonts picked and the palette
theme=$(<"$file")
status=0

if tmux info &>/dev/null; then
    tmux source-file "$HOME/.config/tmux/tmux.conf"
fi

exit $status
