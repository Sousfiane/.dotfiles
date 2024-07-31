alias ijavac='javac -cp ~/dev/devS1/program.jar:.'
alias ijava='java -cp ~/dev/devS1/program.jar:.'
alias javacfx='javac --module-path /home/thibault/.java/javafx-sdk-17.0.11/lib --add-modules=javafx.controls,javafx.fxml'
alias javafx='java --module-path /home/thibault/.java/javafx-sdk-17.0.11/lib --add-modules=javafx.controls,javafx.fxml'

alias shutdown='shutdown now'

alias ls='ls --color'
alias cp="cp -i"
alias df='df -h'
alias free='free -m'

alias ps='sudo pacman -S'
alias pr='sudo pacman -R'
alias pu='sudo pacman -Syu'
alias pc='sudo pacman -Sc'

alias y='yay'
alias ys='yay -S'
alias yr='yay -R'
alias yc='yay -Sc'

alias vim='nvim'
alias svim='sudo -E nvim'

alias gadd='git add'
alias gcom='git commit -m'
alias gpush='git push -u'
alias gpull='git pull'
alias grm='git rm'

alias c='clear'
alias s='source ~/.zshrc'

alias wifi='networkmanager_dmenu &'

alias powersave='sudo cpupower frequency-set --governor powersave'
alias balanced='sudo cpupower frequency-set --governor schedutils'

alias aliases='nvim $DOTFILES/zsh/aliases.zsh'

alias ts='bash $DOTFILES/scripts/tmux-sessionizer.sh'
alias ta='tmux a'
alias tls='tmux ls'

alias dotfiles='bash $DOTFILES/scripts/tmux-sessionizer.sh $DOTFILES'
alias config='bash $DOTFILES/scripts/tmux-sessionizer.sh $HOME/.config'

alias neofetch='fastfetch --config neofetch.jsonc'

take() {
    mkdir -p $1
    cd $1
}

finder() {
    if [[ $(pwd) == $HOME ]]; then
        selected=$(fd -L -t f --follow --search-path $HOME --search-path $DOTFILES | fzf)
    else
        selected=$(fd -L -t f | fzf)
    fi

    [[ -z $selected ]] || nvim $selected
}

note() {
    echo "date: $(date)" >> $HOME/drafts.txt
    echo "$@" >> $HOME/drafts.txt
    echo "" >> $HOME/drafts.txt
}
