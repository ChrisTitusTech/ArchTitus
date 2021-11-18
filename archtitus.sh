#!/bin/bash

read -t 60 -p 'Welcome! Please wait 60 seconds for lingering tasks (time set, reflector, graphical interface...) to complete. Press enter to skip.'

status=$?
cmd="bash 0-preinstall.sh"
$cmd
status=$? && [ $status -eq 0 ] || exit

arch-chroot /mnt /root/ArchTitus/1-setup.sh
source /mnt/root/ArchTitus/install.conf #read config file
arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/ArchTitus/2-user.sh
arch-chroot /mnt /root/ArchTitus/3-post-setup.sh
