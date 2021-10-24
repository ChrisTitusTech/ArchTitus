#!/bin/bash

    bash 0-preinstall.sh
    arch-chroot /mnt /root/autoarch/1-setup.sh
    source /mnt/root/autoarch/install.conf
    arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/autoarch/2-user.sh
    arch-chroot /mnt /root/autoarch/3-post-setup.sh