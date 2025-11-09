#!/bin/env bash

selected=$(wofi -S drun -aI -p Apps --define=drun-print_desktop_file=true | sed -E "s/(\.desktop) /\1:/")

[ -z $selected ] || uwsm-app -- $selected
