#!/usr/bin/env bash

info () {
    printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
    printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
    printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

wait_for_internet(){
    until wget -q --spider duckduckgo.com
    do
        sleep 15
    done
}

status(){
    index=$(git -C "$HOME"/.dotfiles status -s | wc -l)
    if [ "$index" = 0 ]; then
        echo %{F#9ccfd8}""
    else
        echo %{F#eb6f92}"$index"
    fi
}

notify(){
    if [ "$index" = 0 ]; then
        notify-send Dotfiles are up to date !
    else
        notify-send "$(git -C "$HOME"/.dotfiles status -s)"
    fi
   }

pull(){
    index=$(git -C "$HOME"/.dotfiles status -s | wc -l)
    if [ "$index" = 0 ];then
        notify-send "$(git -C "$HOME"/.dotfiles pull --rebase)"
    else
        git -C "$HOME"/.dotfiles stash 
        notify-send "$(git -C "$HOME"/.dotfiles pull --rebase)"
        git -C "$HOME"/.dotfiles stash pop
    fi
}

push(){
    pull
    git -C "$HOME"/.dotfiles add .
    git -C "$HOME"/.dotfiles commit --allow-empty -m "Auto update : $(date)" 
    notify-send "$(git -C "$HOME"/.dotfiles push --porcelain)"
}

sync(){
    wait_for_internet
    git -C "$HOME"/.dotfiles fetch
    status=$(git -C "$HOME"/.dotfiles status --porcelain=v1)
    if [[ -n "$status" ]]; then
        push
    else
        pull
    fi
    exit
}

[[ $1 == "status" ]] && status
[[ $1 == "notify" ]] && notify
[[ $1 == "sync" ]] && sync

