#!/bin/bash

    bash 0-preinstall.sh
    arch-chroot /mnt /root/ArchHodag/1-setup.sh
    source /mnt/root/ArchHodag/install.conf
    arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/ArchHodag/2-user.sh
    arch-chroot /mnt /root/ArchHodag/3-post-setup.sh