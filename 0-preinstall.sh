#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
#  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
#  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
#  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
#-------------------------------------------------------------------------

function formatdisk {
    # disk prep
    sgdisk -Z ${1} # zap all on disk
    sgdisk -a 2048 -o ${1} # new gpt disk 2048 alignment

    # create partitions
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${1} # partition 1 (BIOS Boot Partition)
    sgdisk -n 2::+100M --typecode=2:ef00 --change-name=2:'BOOT' ${1} # partition 2 (UEFI Boot Partition)
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${1} # partition 3 (Root), default start, remaining
    if [[ ! -d "/sys/firmware/efi" ]]; then
        sgdisk -A 1:set:2 ${1}
    fi

    # make filesystems
    if [[ ${1} =~ "nvme" ]]; then
        mkfs.vfat -F32 -n "BOOT" "${1}p2"
        mkfs.btrfs -L "ROOT" "${1}p3" -f
        mount -t btrfs "${1}p3" /mnt
    else
        mkfs.vfat -F32 -n "BOOT" "${1}2"
        mkfs.btrfs -L "ROOT" "${1}3" -f
        mount -t btrfs "${1}3" /mnt
    fi
    ls /mnt #| xargs btrfs subvolume delete #ERROR: btrfs subvolumne delete: not enough arguments: 0 but at least 1 expected
    btrfs subvolume create /mnt/@
    umount /mnt
       
    ~/ArchTitus/x-mount.sh
}


function install {
    ISO=$(curl -4 ifconfig.co/country-iso)
    echo "-------------------------------------------------------------------------"
    echo "--             Setting up $ISO mirrors for faster downloads              --"
    echo "-------------------------------------------------------------------------"
    pacman -S --noconfirm reflector rsync
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    echo "reflector is running, please wait..."
    reflector -a 48 -c $ISO -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
    
    # Add parallel downloading
    sed -i 's/^#Para/Para/' /etc/pacman.conf

    # Enable multilib
    sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    pacman -Sy --noconfirm


    echo "-------------------------------------------------------------------------"
    echo "--                     Base Install on Main Drive                      --"
    echo "-------------------------------------------------------------------------"
    pacstrap /mnt linux base sudo networkmanager iwd --noconfirm --needed
    genfstab -U /mnt >> /mnt/etc/fstab
    #echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
    cp -R ${SCRIPT_DIR} /mnt/root/ArchTitus
    cp /mnt/etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist.backup
    cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist	    
    
    #GRUB has been flaky...moving to chroot...BE SURE TO INSTALL GRUB IF YOU MOVE BACK
    #echo "-------------------------------------------------------------------------"
    #echo "--                      GRUB Bootloader Install                        --"
    #echo "-------------------------------------------------------------------------"
    #if [[ ! -d "/sys/firmware/efi" ]]; then
    #    echo "Detected BIOS"
    #    grub-install --boot-directory=/mnt/boot ${1}
    #fi
    #if [[ -d "/sys/firmware/efi" ]]; then
    #    echo "Detected EFI"
    #    grub-install --efi-directory=/mnt/boot --root-directory=/mnt
    #fi
    
    echo "-------------------------------------------------------------------------"
    echo "--                Check for low memory systems <8G                     --"
    echo "-------------------------------------------------------------------------"
    TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
    if [[  $TOTALMEM -lt 8000000 ]]; then
        #Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
        mkdir /mnt/opt/swap #make a dir that we can apply NOCOW to to make it btrfs-friendly.
        chattr +C /mnt/opt/swap #apply NOCOW, btrfs needs that.
        dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
        chmod 600 /mnt/opt/swap/swapfile #set permissions.
        chown root /mnt/opt/swap/swapfile
        mkswap /mnt/opt/swap/swapfile
        swapon /mnt/opt/swap/swapfile
        #The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the sysytem itself.
        echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab #Add swap to fstab, so it KEEPS working after installation.
    fi
}


# Misc Setup
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
timedatectl set-ntp true
pacman -S --noconfirm terminus-font
setfont ter-v22b

# Read config file, if it exists
configFileName=${HOME}/ArchTitus/install.conf
if [ -e "$configFileName" ]; then
	echo "Using configuration file $configFileName."
	. $configFileName
fi

echo -e "-------------------------------------------------------------------------"
echo -e "   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗"
echo -e "  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝"
echo -e "  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗"
echo -e "  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║"
echo -e "  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║"
echo -e "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝"

# Get Disk
if [ -e "$configFileName" ] && [ ! -z "$disk" ]; then
    echo -e "-------------------------------------------------------------------------"
    echo -e "-- User     - $username"
    echo -e "-- Password - $password"  
    echo -e "-- Host     - $hostname"
    echo -e "-- Disk     - $disk"
    echo -e "-------------------------------------------------------------------------"
    echo -e "   *Blank values will be asked for during setup process..."
    echo -e "-------------------------------------------------------------------------"
    if [ "$password" == "*!*CHANGEME*!*...and-dont-store-in-plantext..." ]; then
        while true; do
	    read -s -p "Password for $username: " password
	    echo
	    read -s -p "Password for $username (again): " password2
	    echo
	    if [ "$password" = "$password2" ] && [ "$password" != "" ]; then
	    	break
	    fi
	    echo "Please try again"
	done
	sed -i.bak "s/^\(password=\).*/\1$password/" $configFileName
    fi
    lsblk
else
    echo -e "-------------------------------------------------------------------------"
    echo -e " Configuration File $configFileName not found..."
    echo -e " Will ask for disk, user, password and hostname during setup process...  "
    echo -e "-------------------------------------------------------------------------"
    echo -e "------------------------select your disk to format-----------------------"
    echo -e "-------------------------------------------------------------------------"
    lsblk
    echo "Please enter disk to format: (example /dev/sda)"
    read disk
    disk="${disk,,}"
    if [[ "${disk}" != *"/dev/"* ]]; then
        disk="/dev/${disk}"
    fi
    echo "disk=$disk" >> $configFileName
fi
echo "THIS WILL FORMAT AND DELETE ALL DATA ON ${disk}"
read -p "are you sure you want to continue (Y/N):" formatdisk
case $formatdisk in
    y|Y|yes|Yes|YES)
        echo "-------------------------------------------------------------------------"
        echo -e "\nFormatting ${disk}..."
        echo "-------------------------------------------------------------------------"
        formatdisk "${disk}"
    ;;
    *)
        echo "Figure out your drive situation, and try again."
        exit 1
    ;;
esac

install "${disk}"
echo "ready for 'arch-chroot /mnt /root/ArchTitus/1-setup.sh'"
