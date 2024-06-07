#!/usr/bin/env bash

path=${HOME}/.config/polybar/scripts/arch/
#trap 'exit' SIGINT

  main_loop() {
    while true; do
      echo '' > ${path}status
      check_for_updates
      sleep 600
    done
  }

  status() {
    echo $$ > ${path}polybar_updates.pid
    while true; do
      cat ${path}status
      sleep 1
    done
  }

  check_for_updates() {
    checkupdates >| ${path}repo.pkgs
    paclist aurpkgs | aur vercmp | sed 's/://' >| ${path}aur.pkgs
    updates=$(cat ${path}repo.pkgs ${path}aur.pkgs | wc -l)
    echo "%{F#9ccfd8}" >| ${path}status
    [ $updates -gt 0 ] && echo "%{F#eb6f92}$updates" >| ${path}status
  }

  notify() {
    if  [ -s ${path}repo.pkgs ]; then
        [ -s ${path}aur.pkgs ] && notify-send "$(cat <(cat ${path}repo.pkgs) <(echo) <(cat ${path}aur.pkgs | sed '1iAURUpdates') | \
                                column -t -L -o " " | sed 's/AURUpdates/AUR Updates/')" || notify-send "$(cat ${path}repo.pkgs | column -t -L -o " ")"
    elif  [ -s ${path}aur.pkgs ]; then
      notify-send "$(cat ${path}aur.pkgs | column -t -L -o " " | sed '1iAUR Updates')"
    else
      notify-send "Arch is up to date !"
    fi
  }

  [[ $# -eq 0 ]] && main_loop
  [[ $1 == "-s" ]] && status
  [[ $1 == "-q" ]] && echo '' > ${path}status && check_for_updates
  [[ $1 == "-n" ]] && notify
