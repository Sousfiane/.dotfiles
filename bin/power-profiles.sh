#!/bin/env bash

selected=$(tlpctl | tac | wofi -S dmenu -p "Power Profiles" -H 150 --cache-file=/dev/null)

[[ -z $selected ]] && exit 0

tlpctl set "${selected##* }"
