#!/usr/bin/env bash

check_for_updates(){
    index=$(checkupdates | wc -l)
    if [[ "$index" = 0 ]]; then 
        echo %{F#9ccfd8}""
    else
        echo %{F#eb6f92}"$index"
    fi
}

notify(){
    notify-send "$(checkupdates --nocolor)"
}

[[ $# -eq 0 ]] && check_for_updates
[[ $1 == "-n" ]] && notify 

