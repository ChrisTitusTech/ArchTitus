#!/bin/bash

    bash 0-preinstall.sh
    arch-chroot /mnt /root/BetterArch/1-setup.sh
    source /mnt/root/BetterArch/install.conf
    arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/BetterArch/2-user.sh
    arch-chroot /mnt /root/BetterArch/3-post-setup.sh