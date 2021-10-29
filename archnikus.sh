#!/bin/bash

PROJECTNAME="ArchNikus"

    bash 0-preinstall.sh
    arch-chroot /mnt /root/$PROJECTNAME/1-setup.sh
    source /mnt/root/$PROJECTNAME/install.conf
    arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/$PROJECTNAME/2-user.sh
    arch-chroot /mnt /root/$PROJECTNAME/3-post-setup.sh