#!/usr/bin/env bash

drive="$HOME/drive/"

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

mount_drive(){
    wait_for_internet
    if [[ -z $(ls $drive) ]]; then
        rclone mount mydrive: $HOME/drive --config $HOME/.config/rclone/rclone.conf --no-checksum --vfs-cache-mode=full &
        success "Drive successfully mounted"
        notify-send "Drive successfully mounted"
    else
        info "Drive already mounted"
        notify-send "Drive already mounted"
    fi
    exit
}

unmount_drive(){
    if [[ ! -z $(ls $drive) ]]; then
        fusermount -u $drive
        success "Drive successfully unmounted"
        exit
    else
        info "Drive already unmounted"
    fi
    exit
}

[[ $1 == "-m" ]] && mount_drive
[[ $1 == "-u" ]] && unmount_drive
