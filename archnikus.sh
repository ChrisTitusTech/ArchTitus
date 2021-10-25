#!/bin/bash

    bash 0-preinstall.sh
    arch-chroot /mnt /root/ArchNikus/1-setup.sh
    source /mnt/root/ArchNikus/install.conf
    arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/ArchNikus/2-user.sh
    arch-chroot /mnt /root/ArchNikus/3-post-setup.sh