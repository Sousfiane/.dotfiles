# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Use powerline
USE_POWERLINE="true"
# Has weird character width
# Example:
#    is not a diamond
HAS_WIDECHARS="false"
# Source manjaro-zsh-configuration
if [[ -e /usr/share/zsh/manjaro-zsh-config ]]; then
  source /usr/share/zsh/manjaro-zsh-config
fi
# Use manjaro zsh prompt
if [[ -e /usr/share/zsh/manjaro-zsh-prompt ]]; then
  source /usr/share/zsh/manjaro-zsh-prompt
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ijava
alias ijavac='javac -cp ~/dev/devS1/program.jar:.'
alias ijava='java -cp ~/dev/devS1/program.jar:.'

# other
alias shutdown='shutdown now'

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
alias svim='sudo nvim'
alias hvim='cd && nvim ~'
alias cvim='cd ~/.config && nvim ~/.config'

alias dev='cd ~/dev/ && nvim ~/dev/'
alias devS1='cd ~/dev/devS1/ && nvim ~/dev/devS1/'
alias devS2='cd ~/dev/devS2/ && nvim ~/dev/devS2/'

alias wallpaper='~/.dotfiles/scripts/wallpapers.sh'

alias c='clear'
