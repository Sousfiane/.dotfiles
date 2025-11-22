alias shutdown='shutdown now'

alias ls='ls --color'
alias cp="cp -i"
alias df='df -h'
alias free='free -m'

alias vim='nvim'
alias svim='sudo -E nvim'

alias c='clear'
alias s='source ~/.zshrc'

alias wifi='networkmanager_dmenu &'

alias powersave='sudo cpupower frequency-set --governor powersave'
alias balanced='sudo cpupower frequency-set --governor schedutils'

alias aliases='nvim $DOTFILES/zsh/aliases.zsh'

alias neofetch='fastfetch --config neofetch.jsonc'

alias gcc="gcc -Wall -Wextra -Werror"

take() {
    mkdir -p $1
    cd $1
}

note() {
    echo "date: $(date)" >> $HOME/drafts.txt
    echo "$@" >> $HOME/drafts.txt
    echo "" >> $HOME/drafts.txt
}
