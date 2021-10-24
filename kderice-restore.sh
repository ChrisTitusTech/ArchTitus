#!/bin/bash

export PATH=$PATH:~/.local/bin
cp -r $HOME/autoarch/dotfiles/* $HOME/.config/
pip install konsave
konsave -i $HOME/autoarch/kde.knsv
sleep 1
konsave -a kde
