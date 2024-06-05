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


cd_dotfiles(){
    cd "$HOME/.dotfiles" || exit
}

notify(){
    cd_dotfiles
    notify-send "$(git status -s)"
}

status(){
    cd_dotfiles
    index=$(git status -s | wc -l)

    if [ $index = 0 ]; then
        echo $index
    else
        echo %{F#eb6f92}$index
    fi
}

push(){
    cd_dotfiles

    actions(){
        info "Here are the files in the index : "
        git status -s | sed 's/^/        /'
        user "Do you want to push those files ? (Y/n)"
        read answer
        case $answer in
            [nN]* ) info "Exiting" ;
                    exit ;;
            * )     git add . ;
                    git commit -m "Auto update $(date)" ;
                    git push -u origin main ;
                    success "Files has been pushed successfully !" ;;
        esac
    }

    actions
    sleep 2
}

pull(){
    cd_dotfiles

    actions(){
        user "Do you want to pull from remote ? (Y/n)"
        read answer
        case $answer in
            [nN]* ) info "Exiting" ;
                    exit ;;
            * )     git stash ;
                    git pull ;
                    success "Files has been updated" ;;
        esac
    }

    actions
    sleep 2
}


auto_pull(){
    git -C $DOTFILES stash
    git -C $DOTFILES  pull --rebase
    git -C $DOTFILES stash pop
}

auto_push(){
    auto_pull
    git -C $DOTFILES add .
    echo 'lol'
    git -C $DOTFILES commit --allow-empty -m "$(date)"
    git -C $DOTFILES push
}

sync(){
    wait_for_internet
    git -C $DOTFILES fetch
    status=$(git -C $DOTFILES status --porcelain=v1)
    if [[ -n "$status" ]]; then
        auto_push
    else
        auto_pull
    fi
}

[[ $1 == "status" ]] && status
[[ $1 == "notify" ]] && notify
[[ $1 == "push" ]] && push 
[[ $1 == "pull" ]] && pull
[[ $1 == "sync" ]] && sync

