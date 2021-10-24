#!/bin/bash

export PATH=$PATH:~/.local/bin
cp -r $HOME/BetterArch/dotfiles/* $HOME/.config/
pip install konsave
konsave -i $HOME/BetterArch/kde.knsv
sleep 1
konsave -a kde
