#!/usr/bin/env bash

cd "$(dirname "$0")/.."
DOTFILES=$(pwd -P)

set -e

echo ''

info () {
    printf "\r  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
    printf "\r  [ \033[0;33m??\033[0m ] $1\n"
}

success () {
    printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
    printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
    echo ''
    exit
}

link_file () {
    local src=$1 dst=$2

    local overwrite=
    local backup=
    local skip=
    local action=

    if [ -f "$dst" ] || [ -d "$dst" ] || [ -L "$dst" ]; then

        if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ];then
            # ignoring exit 1 from readlink in case where file already exists
            # shellcheck disable=SC2155
            local currentSrc="$(readlink $dst)"

            if [ "$currentSrc" == "$src" ]; then
                skip=true;
            else
                user "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
                [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
                read -n 1 action  < /dev/tty
                case "$action" in
                    o )
                        overwrite=true;;
                    O )
                        overwrite_all=true;;
                    b )
                        backup=true;;
                    B )
                        backup_all=true;;
                    s )
                        skip=true;;
                    S )
                        skip_all=true;;
                    * )
                                ;;
                esac
            fi

        fi

        overwrite=${overwrite:-$overwrite_all}
        backup=${backup:-$backup_all}
        skip=${skip:-$skip_all}

        if [ "$overwrite" == "true" ]; then
            rm -rf "$dst"
            success "removed $dst"
        fi

        if [ "$backup" == "true" ]; then
            mv "$dst" "${dst}.backup"
            success "moved $dst to ${dst}.backup"
        fi

        if [ "$skip" == "true" ]; then
            success "skipped $src"
        fi
    fi

    if [ "$skip" != "true" ]  # "false" or empty
    then
        ln -s "$1" "$2"
        success "linked $1 to $2"
    fi
}


prop () {
    PROP_KEY=$1
    PROP_FILE=$2
    PROP_VALUE=$(eval echo "$(cat $PROP_FILE | grep "$PROP_KEY" | cut -d'=' -f2)")
    echo $PROP_VALUE
}

install_dotfiles () {
    info 'installing dotfiles'

    local overwrite_all=false backup_all=false skip_all=false

    find -H "$DOTFILES" -maxdepth 2 -name 'links.prop' -not -path '*.git*' | while read linkfile
do
    cat "$linkfile" | while read line
    do
        local src dst dir
        src=$(eval echo "$line" | cut -d '=' -f 1)
        dst=$(eval echo "$line" | cut -d '=' -f 2)
        dir=$(dirname $dst)

        mkdir -p "$dir"
        link_file "$src" "$dst"
    done
done
}

create_env_file () {
    if test -f "$HOME/.env.sh"; then
        success "$HOME/.env.sh file already exists, skipping"
    else
        echo "export DOTFILES=$DOTFILES" > $HOME/.env.sh
        success 'created ~/.env.sh'
    fi
}

install_yay(){
    info "installing yay"
    sudo pacman -Sy --needed git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    rm -rf yay
    success "yay installed successfully"
}

install_programs(){
    info "installing programs"
    bat=/sys/class/power_supply/BAT0/capacity
    database=$DOTFILES/scripts/packages.pacman
    yay -S  $(cat "$database" | grep -v "##" )
    if [ -f $bat ]; then
        yay -S $(cat "$database" | grep "##" | tr -d "##")
    fi
    success "programs installed successfully"
}

exit=0

while [ $exit -ne 1 ]
do
    echo "1 - Install dotfiles"
    echo "2 - Install yay"
    echo "3 - Install programs"
    echo "4 - Exit"

    read -n 1 choice < /dev/tty;

    case $choice in
        1)  install_dotfiles ;
            create_env_file ;;
        2)  install_yay ;;
        3)  install_programs ;;
        4)  exit=1 ;;
        *)  echo "Not a valid choice"
    esac
done

