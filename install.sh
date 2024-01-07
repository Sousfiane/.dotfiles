#!/bin/sh

echo installing config
ln -sfi ~/.dotfiles/.p10k.zsh ~/ 
ln -sfi ~/.dotfiles/.zshrc ~/ 
ln -sfi ~/.dotfiles/.config/* ~/.config/ 
