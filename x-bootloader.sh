#!/usr/bin/env bash

# Read config file, if it exists
configFileName=${HOME}/ArchTitus/install.conf
if [ -e "$configFileName" ]; then
	echo "Using configuration file $configFileName."
	. $configFileName
fi

# Check partitions are mounted
if ! grep -qs '/boot ' /proc/mounts; then
        umount -fl /mnt
    	~/ArchTitus/x-mount.sh
	arch-chroot /mnt /root/ArchTitus/x-bootloader.sh
	echo "Done.  Please reboot to see if it works now.".
	exit
fi

# install grub
if [[ ! -d "/sys/firmware/efi" ]]; then
	pacman -S grub --noconfirm --needed
	echo "Detected BIOS..."
	if [ -z "$disk" ]; then
		lsblk
		echo "Please enter disk to install bootloader to: (example /dev/sda)"
		read disk
		disk="${disk,,}"
		if [[ "${disk}" != *"/dev/"* ]]; then
			disk="/dev/${disk}"
		fi
	else
		echo "Installing BIOS GRUB to $disk."
	fi
	grub-install --boot-directory=/boot $disk
fi
if [[ -d "/sys/firmware/efi" ]]; then
    pacman -S grub efibootmgr --noconfirm --needed
    echo "Detected EFI..."
    grub-install --efi-directory=/boot
fi

grubfile=/boot/grub/grub.cfg
grub-mkconfig -o $grubfile

if [[ -s $grubfile ]]; then
	cat $grubfile
   	echo "$grubfile exists (and not empty?)"
else
	echo ""
	echo "$grubfile doesn't exist or is empty.  Is grub downloading correctly?".
	echo "Sometimes file wont exist, or a grub.new file is presnet in /boot/grub"
	echo "Other times the file will be blank and grub-mkconfig outputs nothing..."
	echo "Try installing Arch again or break the script here and investigate"
	echo "You'll find the following commands useful to investigate..."
	echo "arch-chroot /mnt"
	echo "grub-mkconfig -o $grubfile"
	read -n 1 -s -r -p "Your system will not boot.  Press any key to continue...or manually break script here."
fi
