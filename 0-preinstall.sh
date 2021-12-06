#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
#  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
#  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
#  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
#-------------------------------------------------------------------------
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
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
source setup.conf
iso=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm pacman-contrib terminus-font
setfont ter-v22b
sed -i 's/^#Para/Para/' /etc/pacman.conf
pacman -S --noconfirm reflector rsync grub
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
pacman -S --noconfirm gptfdisk btrfs-progs
echo -ne "
-------------------------------------------------------------------------
                    Formating Disk
-------------------------------------------------------------------------
"
# disk prep
sgdisk -Z ${DISK} # zap all on disk
sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# create partitions
sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
sgdisk -n 2::+100M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
    sgdisk -A 1:set:2 ${DISK}
fi
# make filesystems
echo -ne "
-------------------------------------------------------------------------
                    Creating Filesystems
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
    mount -o noatime,compress=zstd,space_cache,commit=120,subvol=@home /dev/mapper/ROOT /mnt/home
    mount -o noatime,compress=zstd,space_cache,commit=120,subvol=@tmp /dev/mapper/ROOT /mnt/tmp
    mount -o noatime,compress=zstd,space_cache,commit=120,subvol=@.snapshots /dev/mapper/ROOT /mnt/.snapshots
    mount -o subvol=@var /dev/mapper/ROOT /mnt/var
}
if [[ "${DISK}" == "nvme" ]]; then
    if [[ "${FS}" == "btrfs" ]]; then
        mkfs.vfat -F32 -n "EFIBOOT" ${DISK}p2
        mkfs.btrfs -L ROOT ${DISK}p3 -f
        mount -t btrfs ${DISK}p3 /mnt
    elif [[ "${FS}" == "ext4" ]]; then
        mkfs.vfat -F32 -n "EFIBOOT" ${DISK}p2
        mkfs.ext4 -L ROOT ${DISK}p3
        mount -t ext4 ${DISK}p3 /mnt
    elif [[ "${FS}" == "luks" ]]; then
        mkfs.vfat -F32 -n "EFIBOOT" ${DISK}p2
# enter luks password to cryptsetup and format root partition
        echo -n "${luks_password}" | cryptsetup -y -v luksFormat ${DISK}p3 -
# open luks container and ROOT will be place holder 
        echo -n "${luks_password}" | cryptsetup open ${DISK}p3 ROOT -
# now format that container
        mkfs.btrfs -L ROOT /dev/mapper/ROOT
# create subvolumes for btrfs
        mount -t btrfs /dev/mapper/ROOT /mnt
        createsubvolumes       
        umount /mnt
# mount @ subvolume
        mount -o noatime,compress=zstd,space_cache,commit=120,subvol=@ /dev/mapper/ROOT /mnt
# make directories home, .snapshots, var, tmp
        mkdir -p /mnt/{home,var,tmp,.snapshots}
# mount subvolumes
        mountallsubvol
    fi
else
    if [[ "${FS}" == "btrfs" ]]; then
        mkfs.vfat -F32 -n "EFIBOOT" ${DISK}2
        mkfs.btrfs -f -L ROOT ${DISK}3
        mount -t btrfs ${DISK}3 /mnt
    elif [[ "${FS}" == "ext4" ]]; then
        mkfs.vfat -F32 -n "EFIBOOT" ${DISK}2
        mkfs.ext4 -L ROOT ${DISK}3
        mount -t ext4 ${DISK}3 /mnt
    elif [[ "${FS}" == "luks" ]]; then
        mkfs.vfat -F32 -n "EFIBOOT" ${DISK}2
        echo -n "${luks_password}" | cryptsetup -y -v luksFormat ${DISK}3 -
        echo -n "${luks_password}" | cryptsetup open ${DISK}3 ROOT -
        mkfs.btrfs -L ROOT /dev/mapper/ROOT
        mount -t btrfs /dev/mapper/ROOT /mnt
        createsubvolumes
        umount /mnt
# mount all the subvolumes
        mount -o noatime,compress=zstd,space_cache,commit=120,subvol=@ /dev/mapper/ROOT /mnt
# make directories home, .snapshots, var, tmp
        mkdir -p /mnt/{home,var,tmp,.snapshots}
# mount subvolumes
        mountallsubvol
    fi
fi
# checking if user selected btrfs
if [[ ${FS} =~ "btrfs" ]]; then
ls /mnt | xargs btrfs subvolume delete
btrfs subvolume create /mnt/@
umount /mnt
mount -t btrfs -o subvol=@ -L ROOT /mnt
fi

# mount target
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

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
genfstab -U /mnt >> /mnt/etc/fstab
echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
cp -R ${SCRIPT_DIR} /mnt/root/ArchTitus
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
echo -ne "
-------------------------------------------------------------------------
                    GRUB BIOS Bootloader Install & Check
-------------------------------------------------------------------------
"
if [[ ! -d "/sys/firmware/efi" ]]; then
    grub-install --boot-directory=/mnt/boot ${DISK}
fi
echo -ne "
-------------------------------------------------------------------------
                    Checking for low memory systems <8G
-------------------------------------------------------------------------
"
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -lt 8000000 ]]; then
    # Put swapfile into separate subvolume or else you wouldn't be able to make snapshots of root
    btrfs subvolume create /mnt/swap
    truncate -s 0 /mnt/swap/swapfile
    chattr +C /mnt/swap/swapfile #apply NOCOW, btrfs needs that.
    btrfs property set /mnt/swap/swapfile compression none
    dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=4096 status=progress
    chmod 600 /mnt/swap/swapfile #set permissions.
    chown root /mnt/swap/swapfile
    mkswap /mnt/swap/swapfile
    swapon /mnt/swap/swapfile
    echo "/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab #Add swap to fstab, so it KEEPS working after installation.
    echo "vm.swappiness=10" >> /mnt/etc/sysctl.conf # Lower swappiness
fi
echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 1-setup.sh
-------------------------------------------------------------------------
"