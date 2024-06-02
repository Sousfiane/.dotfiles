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


push_notify(){
    notify-send "Pushing dotfiles ..."
    git -C /home/thibault/.dotfiles add .
    git -C /home/thibault/.dotfiles commit -m "Auto update $(date)"  
    notify-send "$(git -C /home/thibault/.dotfiles push -u origin main)"
    exit

}

pull_notify(){
    notify-send "Pulling dotfiles .."
    cd /home/thibault/.dotfiles
    notify-send "$(git -C /home/thibault/.dotfiles pull)"
    exit
}

[[ $1 == "status" ]] && status
[[ $1 == "notify" ]] && notify
[[ $1 == "push" ]] && push 
[[ $1 == "pull" ]] && pull
[[ $1 == "pull_notify" ]] && pull_notify
[[ $1 == "push_notify" ]] && push_notify

