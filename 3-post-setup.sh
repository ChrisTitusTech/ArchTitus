#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
#  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
#  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
#  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
#-------------------------------------------------------------------------

echo -e "\nFINAL SETUP AND CONFIGURATION"

# ------------------------------------------------------------------------

echo -e "\nGenerating .xinitrc file"

# Generate the .xinitrc file so we can launch Awesome from the
# terminal using the "startx" command
cat <<EOF > ${HOME}/.xinitrc
#!/bin/bash
# Disable bell
xset -b

# Disable all Power Saving Stuff
xset -dpms
xset s off

# X Root window color
xsetroot -solid darkgrey

# Merge resources (optional)
#xrdb -merge $HOME/.Xresources

# Caps to Ctrl, no caps
setxkbmap -layout us -option ctrl:nocaps
if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "\$f" ] && . "\$f"
    done
    unset f
fi

exit 0
EOF

# ------------------------------------------------------------------------

echo -e "\nConfiguring LTS Kernel as a secondary boot option"

sudo cp /boot/loader/entries/arch.conf /boot/loader/entries/arch-lts.conf
sudo sed -i 's|Arch Linux|Arch Linux LTS Kernel|g' /boot/loader/entries/arch-lts.conf
sudo sed -i 's|vmlinuz-linux|vmlinuz-linux-lts|g' /boot/loader/entries/arch-lts.conf
sudo sed -i 's|initramfs-linux.img|initramfs-linux-lts.img|g' /boot/loader/entries/arch-lts.conf

# ------------------------------------------------------------------------

echo -e "\nIncreasing file watcher count"

# This prevents a "too many files" error in Visual Studio Code
echo fs.inotify.max_user_watches=524288 | sudo tee /etc/sysctl.d/40-max-user-watches.conf && sudo sysctl --system

# ------------------------------------------------------------------------

echo -e "\nDisabling Pulse .esd_auth module"

# Pulse audio loads the `esound-protocol` module, which best I can tell is rarely needed.
# That module creates a file called `.esd_auth` in the home directory which I'd prefer to not be there. So...
sudo sed -i 's|load-module module-esound-protocol-unix|#load-module module-esound-protocol-unix|g' /etc/pulse/default.pa

# ------------------------------------------------------------------------

echo -e "\nEnabling Login Display Manager"

sudo systemctl enable sddm.service

echo -e "\nSetup SDDM Theme"

sudo cat <<EOF > /etc/sddm.conf
[Theme]
Current=Nordic
EOF

# ------------------------------------------------------------------------

echo -e "\nEnabling bluetooth daemon and setting it to auto-start"

sudo sed -i 's|#AutoEnable=false|AutoEnable=true|g' /etc/bluetooth/main.conf
sudo systemctl enable --now bluetooth.service

# ------------------------------------------------------------------------

echo -e "\nEnabling the cups service daemon so we can print"

systemctl enable --now cups.service
sudo ntpd -qg
sudo systemctl enable --now ntpd.service
sudo systemctl disable dhcpcd.service
sudo systemctl stop dhcpcd.service
sudo systemctl enable --now NetworkManager.service
echo "
###############################################################################
# Cleaning
###############################################################################
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Replace in the same state
cd $pwd
echo "
###############################################################################
# Done
###############################################################################
"
