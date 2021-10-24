#!/bin/bash

    bash 0-preinstall.sh
    arch-chroot /mnt /root/AutoArch/1-setup.sh
    source /mnt/root/AutoArch/install.conf
    arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/AutoArch/2-user.sh
    arch-chroot /mnt /root/AutoArch/3-post-setup.sh