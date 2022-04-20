#!/usr/bin/env bash
GNOME_SHELL_VERSION=`gnome-shell --version`
echo $GNOME_SHELL_VERSION #| cut -d " " -f $2

yay -S gnome-shell-extension-installer
EXT_NAME=Material
# get search output (to find current ID)
MY_TEMP="`printf 'q' | gnome-shell-extension-installer $EXT_NAME`"
EXTENSION_ID=...??? # filter version
gnome-shell-extension-installer $EXTENSION_ID
