#!/bin/bash

export PATH=$PATH:~/.local/bin
cp -r $HOME/AutoArch/dotfiles/* $HOME/.config/
pip install konsave
konsave -i $HOME/AutoArch/kde.knsv
sleep 1
konsave -a kde
