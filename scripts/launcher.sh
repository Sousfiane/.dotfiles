#!/bin/bash

dir="$HOME/.config/rofi/launcher"
theme='style-1-icon'

## Run
rofi \
    -show drun \
    -theme ${dir}/${theme}.rasi 
