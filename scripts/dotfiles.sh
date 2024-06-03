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


push_notify(){
    wait_for_internet
    echo "[Last push from $date]" > .lastpush
    echo "\n" >> .lastpush
    git -C /home/thibault/.dotfiles add . -v >> .lastpush 2>&1
    echo "\n" >> .lastpush
    git -C /home/thibault/.dotfiles commit -v -m "Auto update $(date)" >>  .lastpush 2>&1
    echo "\n" >> .lastpush
    git -C /home/thibault/.dotfiles push -v -u origin main >> .lastpush 2>&1
    exit

}

pull_notify(){
    wait_for_internet
    notify-send "Pulling dotfiles .."
    notify-send "$(git -C /home/thibault/.dotfiles pull)"
    exit
}

[[ $1 == "status" ]] && status
[[ $1 == "notify" ]] && notify
[[ $1 == "push" ]] && push 
[[ $1 == "pull" ]] && pull
[[ $1 == "pull_notify" ]] && pull_notify
[[ $1 == "push_notify" ]] && push_notify

