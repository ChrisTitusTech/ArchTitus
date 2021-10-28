#!/bin/bash

# Find the name of the folder the scripts are in

# X! Still erroring out, doesnt get the directory no matter what.
# I hate it

export SCRIPTHOME="$(basename -- $PWD)"
echo "Scripts are in dir named $SCRIPTHOME"
cd $PWD

    bash 0-preinstall.sh
    arch-chroot /mnt /root/$SCRIPTHOME/1-setup.sh
    source /mnt/root/$SCRIPTHOME/install.conf
    arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/$SCRIPTHOME/2-user.sh
    arch-chroot /mnt /root/$SCRIPTHOME/3-post-setup.sh

# Replace in the same state
cd $PWD
echo "
###############################################################################
# Done - Please Eject Install Media and Reboot (you can just type 'reboot')
###############################################################################
"