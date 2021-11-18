#!/usr/bin/env bash

    # mount target
    echo "Mounting Filesystems..."
    mount -t btrfs -o subvol=@ -L ROOT /mnt
    mkdir /mnt/boot
    mkdir /mnt/boot/efi
    mount -t vfat -L BOOT /mnt/boot

    if ! grep -qs '/mnt' /proc/mounts; then
        echo "Drive did not mount correctly.  Can not continue!"
        read -n 1 -s -r -p "Press any key to reboot..."
        reboot now
    fi
