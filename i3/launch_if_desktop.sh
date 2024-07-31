#!/bin/bash

bat="/sys/class/power_supply/BAT0/capacity"

if [ -f $bat ]; then
    exit
else
    exec $1
fi
