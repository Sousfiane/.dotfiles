#!/usr/bin/env bash

drive="$HOME/.mydrive/"

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
        exit
    done
}

mount_drive(){
        if [[ -z $(ls $drive) ]]; then
            rclone mount mydrive: $HOME/.mydrive --config $HOME/.config/rclone/rclone.conf --no-checksum --vfs-cache-mode=full &
            success "Drive successfully mounted"
            notify-send "Drive successfully mounted"
        else
            info "Drive already mounted"
            notify-send "Drive already mounted"
        fi
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

create_symlinks(){
    for file in `ls $drive`
    do
        if [ ! -L $HOME/$file ]; then
            ln -s $drive/$file $HOME/$file
            success "$HOME/$file symlink created"
        else
            info "$HOME/$file symlink already exists"
        fi
    done
    exit
}

delete_symlinks(){
    if [[ ! -z $(ls $drive) ]]; then
        for file in `ls $drive`
        do
            if [ -L $HOME/$file ]; then
                rm $HOME/$file
                success "$HOME/$file symlink deleted"
            else
                info "$HOME/$file symlink doesn't exists"
            fi
        done
    else
        info "The drive is not mounted"
    fi
}

mount_link(){
    wait_for_internet
    mount_drive
    sleep 2
    create_symlinks
}

[[ $1 == "-m" ]] && mount_drive
[[ $1 == "-l" ]] && create_symlinks
[[ $1 == "-d" ]] && delete_symlinks 
[[ $1 == "-u" ]] && unmount_drive
[[ $1 == "-ml" ]] && mount_link
[[ $1 == "-du" ]] && delete_symlinks && unmount_drive
