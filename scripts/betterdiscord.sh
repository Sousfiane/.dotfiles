#!/bin/env bash

status=$(betterdiscordctl status | grep "injected" | cut -d':' -f 2)

echo $status
if [[ $status == "yes" ]]; then
    echo "yes"
fi

