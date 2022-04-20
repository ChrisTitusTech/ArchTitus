#!/usr/bin/env bash

# fix KEYMAP
gsettings reset org.gnome.desktop.input-sources sources
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'de+nodeadkeys')]"

# disable Wayland
sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm/custom.conf

#######################################
###  EXTENSIONS
#######################################
# get gnome version
temp=`gnome-shell --version`
GNOME_VERSION=${temp:12:2} && echo "gnome version: $GNOME_VERSION"

# get extension installer:
yay -S gnome-shell-extension-installer

printf $GNOME_VERSION | gnome-shell-extension-installer 779 # clipboard-indicator
printf $GNOME_VERSION | gnome-shell-extension-installer 277 # impatience
printf $GNOME_VERSION | gnome-shell-extension-installer 3357 # material shell
printf $GNOME_VERSION | gnome-shell-extension-installer 1460 # vitals (cpu/ram/storage/..)
printf $GNOME_VERSION | gnome-shell-extension-installer 1287 # unite (remove window top panel)
printf $GNOME_VERSION | gnome-shell-extension-installer 1112 # screenshot tool
printf $GNOME_VERSION | gnome-shell-extension-installer 3088 # Extension list
printf $GNOME_VERSION | gnome-shell-extension-installer 906 # Sound output chooser

killall -HUP gnome-shell # kill (hopfully restart) gnome-shell
