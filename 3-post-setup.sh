#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
#  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
#  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
#  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
#-------------------------------------------------------------------------

echo "-------------------------------------------------------------------------"
echo "--                          GRUB Bootloader                            --"
echo "-------------------------------------------------------------------------"
    ~/ArchTitus/x-bootloader.sh


echo "-------------------------------------------------------------------------"
echo "--                         Cleaning Up / Misc                          --"
echo "-------------------------------------------------------------------------"
# Remove no password sudo rights granted previously
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Cleanup unused packages
pacman -Rsc --noconfirm "$(pacman -Qqdt)"

# Enable btrfs snapshots
snapper -c root create-config /

# Enable services
systemctl disable dhcpcd.service
systemctl stop dhcpcd.service

systemctl enable sddm.service

ntpd -qg #netowrk time sync
systemctl enable ntpd.service

systemctl enable cups.service
systemctl enable bluetooth

systemctl enable smb.service
systemctl enable nmb.service

systemctl enable NetworkManager.service
systemctl enable NetworkManager-dispatcher.service

# change directory back
cd $pwd

echo "Done!"
