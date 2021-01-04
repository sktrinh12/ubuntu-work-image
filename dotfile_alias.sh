#!/bin/bash
git init --bare $HOME/.config
echo "alias dotfiles='/usr/bin/git --git-dir=${HOME}/.config/ --work-tree=${HOME}'" >> ~/.bashrc
source $HOME/.bashrc
#cd $HOME/.config
#/usr/bin/git --git-dir=${HOME}/.config/ --work-tree=${HOME} config --local status.showUntrackedFiles no
