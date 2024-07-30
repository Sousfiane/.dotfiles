#!/bin/env bash

status=$(betterdiscordctl status | grep "injected" | cut -d':' -f 2)

[[ $status == "no" ]] && echo lol && betterdiscordctl install && killall discord && discord &

