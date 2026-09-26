#!/usr/bin/env bash

set -uo pipefail

selected=$( wofi --show drun --prompt "Apps" --define=drun-print_desktop_file=true) || exit 0

[[ -z "$selected" ]] && exit 0

selected="${selected//$'\n'/}"

exec uwsm-app -- "$selected"
