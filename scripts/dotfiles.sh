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
        sleep 10
    done
}

notify(){
    notify-send "$(git -C $HOME/.dotfiles status -s)"
}

status(){
    index=$(git -C $HOME/.dotfiles status -s | wc -l)
    if [ $index = 0 ]; then
        echo $index
    else
        echo %{F#eb6f92}$index
    fi
}

auto_pull(){
    git -C $HOME/.dotfiles stash 2>&1
    git -C $HOME/.dotfiles pull --rebase 2>&1
    git -C $HOME/.dotfiles stash pop  2>&1
}

auto_push(){
    auto_pull
    git -C $HOME/.dotfiles add .  2>&1
    git -C $HOME/.dotfiles commit --allow-empty -m "$(date)"  2>&1
    git -C $HOME/.dotfiles push  2>&1
}

sync(){
    wait_for_internet
    git -C $HOME/.dotfiles fetch  2>&1
    status=$(git -C $HOME/.dotfiles status --porcelain=v1)
    if [[ -n "$status" ]]; then
        auto_push
    else
        auto_pull
    fi
    exit
}

[[ $1 == "status" ]] && status
[[ $1 == "notify" ]] && notify
[[ $1 == "sync" ]] && sync

