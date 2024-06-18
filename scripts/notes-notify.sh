#!/bin/env bash

notes="$HOME/drafts.txt"

while true; do
    if [ -f "$notes" ]; then
        notify-send "$(cat $notes)"
    fi
    sleep 1200
done

