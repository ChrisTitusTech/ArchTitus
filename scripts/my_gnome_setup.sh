#!/usr/bin/env bash

# setup GIT
git config --global user.email "lukasgraz@gmail.com"
git config --global user.name "LukasGraz"

# disable Wayland
sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' /etc/gdm/custom.conf

# fix KEYMAP
gsettings reset org.gnome.desktop.input-sources sources
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'de+nodeadkeys')]"

# SHORTCUTS
python3 ~/ArchTitus/scripts/add_gnome_shortcuts.py 'open guake' 'guake' '<Super>e'


#######################################
###  EXTENSIONS
#######################################
# get gnome version
temp=`gnome-shell --version`
GNOME_VERSION=${temp:12:2} && echo "gnome version: $GNOME_VERSION"

# get extension installer:
yay -S --noconfirm --needed gnome-shell-extension-installer

printf "$GNOME_VERSION\nq" | gnome-shell-extension-installer 779 # clipboard-indicator
printf "$GNOME_VERSION\nq" | gnome-shell-extension-installer 277 # impatience
printf "$GNOME_VERSION\nq" | gnome-shell-extension-installer 3357 # material shell
printf "$GNOME_VERSION\nq" | gnome-shell-extension-installer 1460 # vitals (cpu/ram/storage/..)
printf "$GNOME_VERSION\nq" | gnome-shell-extension-installer 1287 # unite (remove window top panel)
printf "$GNOME_VERSION\nq" | gnome-shell-extension-installer 1112 # screenshot tool
printf "$GNOME_VERSION\nq" | gnome-shell-extension-installer 3088 # Extension list
printf "$GNOME_VERSION\nq" | gnome-shell-extension-installer 906 # Sound output chooser

killall -HUP gnome-shell # kill (hopfully restart) gnome-shell
enable-extension () {
    gnome-extensions enable $1 || echo "could not enable $1"
}
enable-extension clipboard-indicator@tudmotu.com
enable-extension impatience@gfxmonk.net
enable-extension material-shell@papyelgringo
enable-extension Vitals@CoreCoding.com
enable-extension unite@hardpixel.eu
enable-extension extension-list@tu.berry
enable-extension sound-output-device-chooser@kgshank.net
enable-extension gnome-shell-screenshot@ttll.de

