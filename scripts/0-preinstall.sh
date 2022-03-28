#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
#  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
#  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
#  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
#-------------------------------------------------------------------------
#github-action genshdoc

echo -ne "
-------------------------------------------------------------------------
   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------

Setting up mirrors for optimal download
"
source $CONFIGS_DIR/setup.conf
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm archlinux-keyring #update keyrings to latest to prevent packages failing to install
pacman -S --noconfirm --needed pacman-contrib terminus-font
setfont ter-v22b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm --needed reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -ne "
-------------------------------------------------------------------------
                    Setting up $iso mirrors for faster downloads
-------------------------------------------------------------------------
"
reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt &>/dev/null # Hiding error message if any
echo -ne "
-------------------------------------------------------------------------
                    Installing Prerequisites
-------------------------------------------------------------------------
"
pacman -S --noconfirm --needed gptfdisk btrfs-progs glibc
echo -ne "
-------------------------------------------------------------------------
                    Formating Disk
-------------------------------------------------------------------------
"
createsubvolumes () {
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@tmp
    btrfs subvolume create /mnt/@.snapshots
}

mountallsubvol () {
    mount -o ${MOUNT_OPTIONS},subvol=@home ${rootpartition} /mnt/home
    mount -o ${MOUNT_OPTIONS},subvol=@tmp ${rootpartition} /mnt/tmp
    mount -o ${MOUNT_OPTIONS},subvol=@var ${rootpartition} /mnt/var
    mount -o ${MOUNT_OPTIONS},subvol=@.snapshots ${rootpartition} /mnt/.snapshots
}

subvolumesetup () {
# create nonroot subvolumes
    createsubvolumes     
# unmount root to remount with subvolume 
    umount /mnt
# mount @ subvolume
    mount -o ${MOUNT_OPTIONS},subvol=@ ${rootpartition} /mnt
# make directories home, .snapshots, var, tmp
    mkdir -p /mnt/{home,var,tmp,.snapshots}
# mount subvolumes
    mountallsubvol
}

formatandmount () {
    if [[ "${FS}" == "btrfs" ]]; then
        mkfs.btrfs -L ROOT ${rootpartition} -f
        mount -t btrfs ${rootpartition} /mnt
        subvolumesetup
    elif [[ "${FS}" == "ext4" ]]; then
        mkfs.ext4 -L ROOT ${rootpartition}
        mount -t ext4 ${rootpartition} /mnt
    elif [[ "${FS}" == "luks" ]]; then
# enter luks password to cryptsetup and format root partition
        echo -n "${LUKS_PASSWORD}" | cryptsetup -y -v luksFormat ${rootpartition} -
# open luks container and ROOT will be place holder 
        echo -n "${LUKS_PASSWORD}" | cryptsetup open ${rootpartition} ROOT -
# now format that container
        mkfs.btrfs -L ROOT ${rootpartition}
# create subvolumes for btrfs
        mount -t btrfs ${rootpartition} /mnt
        subvolumesetup
# store uuid of encrypted partition for grub
        echo ENCRYPTED_PARTITION_UUID=$(blkid -s UUID -o value ${rootpartition}) >> $CONFIGS_DIR/setup.conf
    fi
}

umount -A --recursive /mnt # make sure everything is unmounted before we start

if [[ $INSTALL_IN = "PART" ]]; then # Checking if install to partition
    EFIpartition=${BOOTPART}
    rootpartition=${PART}

    if [[ -d "/sys/firmware/efi" ]]; then # Checking for UEFI system
        if [[ $FORMATEFI = "yes" ]]; then
            mkfs.vfat -F32 -n "EFIBOOT" ${EFIpartition}
        fi
        formatandmount
        # mount EFI partition
        mkdir -p /mnt/boot/efi
        mount -t vfat ${EFIpartition} /mnt/boot/efi
    elif [[ $(fdisk -l ${DISK} | grep -i '^Disklabel type') = "Disklabel type: gpt" ]]; then # Checking for GPT Disk Label on a Legacy BIOS (non UEFI) System
        formatandmount
    fi
fi

if [[ $INSTALL_IN = "DISK" ]]; then # Checking if install to disk
    # disk prep
    sgdisk -Z ${DISK} # zap all on disk
    sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

    # create partitions
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # BIOSpartition (BIOS Boot Partition)
    sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # EFIpartition (UEFI Boot Partition)
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # rootpartition (Root), default start, remaining
    if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for BIOS system
        sgdisk -A 1:set:2 ${DISK}
    fi

    if [[ "${DISK}" =~ "nvme" ]]; then
        EFIpartition=${DISK}p2
        rootpartition=${DISK}p3
    else
        EFIpartition=${DISK}2
        rootpartition=${DISK}3
    fi

    mkfs.vfat -F32 -n "EFIBOOT" ${EFIpartition}
    formatandmount
    # mount EFI partition
    mkdir -p /mnt/boot/efi
    mount -t vfat -L EFIBOOT /mnt/boot/efi
fi


if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi
echo -ne "
-------------------------------------------------------------------------
                    Arch Install on Main Drive
-------------------------------------------------------------------------
"
pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/root/ArchTitus
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

genfstab -L /mnt >> /mnt/etc/fstab
echo " 
  Generated /etc/fstab:
"
cat /mnt/etc/fstab
echo -ne "
-------------------------------------------------------------------------
                    GRUB BIOS Bootloader Install & Check
-------------------------------------------------------------------------
"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK}
else
    pacstrap /mnt efibootmgr --noconfirm --needed
fi
echo -ne "
-------------------------------------------------------------------------
                    Checking for low memory systems <8G
-------------------------------------------------------------------------
"
TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTAL_MEM -lt 8000000 ]]; then
    # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir -p /mnt/opt/swap # make a dir that we can apply NOCOW to to make it btrfs-friendly.
    chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile # set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
fi
echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 1-setup.sh
-------------------------------------------------------------------------
"
