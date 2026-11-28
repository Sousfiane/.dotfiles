#!/usr/bin/env bash
# kitty: it reads the theme itself (config/kitty/theme.py, through geninclude); every window reloads its
# config on SIGUSR1.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/../lib.sh"

file=$(theme_current)            # the merged theme: theme.json, the fonts picked and the palette
theme=$(<"$file")
status=0

pkill -USR1 -x kitty 2>/dev/null

exit $status
