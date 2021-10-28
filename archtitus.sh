#!/bin/bash

# Find the name of the folder the scripts are in

# X! Still erroring out, doesnt get the directory no matter what.
# Found potential Solution
# I hate it

cd /
if [ -L $0 ] ; then
    ME=$(readlink $0)
else
    ME=$0
fi
dir=$(dirname $ME)

export SCRIPTHOME="$(basename -- $dir)"
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