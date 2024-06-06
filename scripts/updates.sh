#!/usr/bin/env bash

main_loop(){
    while true; do
        echo ''
        echo ''
        check_for_updates
        sleep 600
    done
}

check_for_updates(){
    index=$(checkupdates | wc -l)
    if [[ "$index" = 0 ]]; then 
        echo %{F#9ccfd8}""
    else
        echo %{F#eb6f92}"$index"
    fi
}

[[ $# -eq 0 ]] && main_loop

