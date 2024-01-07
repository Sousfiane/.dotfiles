#!/bin/sh

echo install config
ln -s ~/.dotfiles/.p10k.zsh ~/ 
ln -s ~/.dotfiles/.zshrc ~/
ln -s ~/.dotfiles/.gitconfig ~/ 
ln -s ~/.dotfiles/.config/* ~/.config/
ln -s ~/.dotfiles/.gtk-3.0/* ~/.config/gtk-3.0/

