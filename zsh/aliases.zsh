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

tv() {
    [[ $1 == "on" ]] && hyprctl keyword monitor "HDMI-A-1,3840x2160@144,-3840x0,1,bitdepth,10"
    [[ $1 == "off" ]] && hyprctl keyword monitor "HDMI-A-1,disable"
}

to-mov(){
    ffmpeg -i $1 -c:v dnxhd -profile:v dnxhr_hq -pix_fmt yuv422p -c:a pcm_s16le "$(echo $1 | cut -d'.' -f1).mov"
}

to-mp4(){
    ffmpeg -i $1 -c:v libx264 -pix_fmt yuv420p -profile:v high -level 4.2 -preset slow -crf 23 -c:a aac -b:a 192k -ar 44100 "$(echo $1 | cut -d'.' -f1).mp4"
}
