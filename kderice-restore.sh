#!/bin/bash

export PATH=$PATH:~/.local/bin
cp -r $HOME/$SCRIPTHOME/dotfiles/* $HOME/.config/
pip install konsave
konsave -i $HOME/$SCRIPTHOME/kde.knsv
sleep 1
konsave -a kde
