#!/usr/bin/env bash

dbus-launch

# setup GIT
git config --global user.email "lukasgraz@gmail.com"
git config --global user.name "LukasGraz"

# download this repo
mkdir Desktop
cd Desktop
git clone https://github.com/Greeenstone/ArchTitus
cd ..

# disable Wayland
sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm/custom.conf

# fix KEYMAP
sudo gsettings reset org.gnome.desktop.input-sources sources
sudo gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'de+nodeadkeys')]"

# SHORTCUTS
# TEMP="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings"
# gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$TEMP/custom0/', '$TEMP/custom1/', '$TEMP/custom2/', '$TEMP/custom3/']"
# gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$TEMP/custom0 ......................................
# ..........................  to complete ...^

#######################################
###  EXTENSIONS
#######################################
# get gnome version
temp=`gnome-shell --version`
GNOME_VERSION=${temp:12:2} && echo "gnome version: $GNOME_VERSION"

# get extension installer:
yay -S --noconfirm --needed gnome-shell-extension-installer

printf "$GNOME_VERSION\nq" | sudo gnome-shell-extension-installer 779 # clipboard-indicator
printf "$GNOME_VERSION\nq" | sudo gnome-shell-extension-installer 277 # impatience
printf "$GNOME_VERSION\nq" | sudo gnome-shell-extension-installer 3357 # material shell
printf "$GNOME_VERSION\nq" | sudo gnome-shell-extension-installer 1460 # vitals (cpu/ram/storage/..)
printf "$GNOME_VERSION\nq" | sudo gnome-shell-extension-installer 1287 # unite (remove window top panel)
printf "$GNOME_VERSION\nq" | sudo gnome-shell-extension-installer 1112 # screenshot tool
printf "$GNOME_VERSION\nq" | sudo gnome-shell-extension-installer 3088 # Extension list
printf "$GNOME_VERSION\nq" | sudo gnome-shell-extension-installer 906 # Sound output chooser

killall -HUP gnome-shell # kill (hopfully restart) gnome-shell
