alias ijavac='javac -cp ~/dev/devS1/program.jar:.'
alias ijava='java -cp ~/dev/devS1/program.jar:.'

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
alias yu='yay -Syu'
alias yc='yay -Sc'

alias vim='nvim'
alias svim='sudo -E nvim'
alias cvim='cd $HOME/.config && nvim $HOME/.config'
alias dvim='cd $DOTFILES && nvim $DOTFILES'

alias gadd='git add'
alias gcom='git commit -m'
alias gpush='git push -u'
alias gpull='git pull'
alias grm='git rm'

alias dev='cd ~/dev/ && nvim ~/dev/'
alias devS1='cd ~/devS1/ && nvim ~/devS1/'
alias devS2='cd ~/dev-oo/ && nvim ~/dev-oo/'

alias wallpapers=$DOTFILES/scripts/wallpapers.sh
alias videos=$DOTFILES/scripts/videos.sh
alias betterdiscord=$DOTFILES/scripts/BetterDiscord-Linux.AppImage

alias c='clear'
alias s='source ~/.zshrc'

alias wifi='networkmanager_dmenu &'

alias powersave='sudo cpupower frequency-set --governor powersave'
alias balanced='sudo cpupower frequency-set --governor schedutils'

alias aliases='vim $DOTFILES/zsh/aliases.zsh'

function take {
    mkdir -p $1
    cd $1
}

note() {
    echo "date: $(date)" >> $HOME/drafts.txt
    echo "$@" >> $HOME/drafts.txt
    echo "" >> $HOME/drafts.txt
}

 function finder {
    selected=$(fd -L -H -t f --exclude '.git .cache' | fzf)
    [[ -z $selected ]] || nvim $selected
 }
