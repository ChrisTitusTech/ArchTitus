#!/bin/bash

# Find the name of the folder the scripts are in
export SCRIPTHOME="$(basename -- $PWD)"
echo "Scripts are in dir named $SCRIPTHOME"

    bash 0-preinstall.sh
    arch-chroot /mnt /root/$SCRIPTHOME/1-setup.sh
    source /mnt/root/$SCRIPTHOME/install.conf
    arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/$SCRIPTHOME/2-user.sh
    arch-chroot /mnt /root/$SCRIPTHOME/3-post-setup.sh

echo "
###############################################################################
# Done - Please Eject Install Media and Reboot
###############################################################################
"