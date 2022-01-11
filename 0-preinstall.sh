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
ISO=$(curl -4 ifconfig.co/country-iso)
timedatectl set-ntp true
pacman -S --noconfirm pacman-contrib terminus-font
setfont ter-v22b
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
pacman -S --noconfirm reflector rsync grub
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -ne "
-------------------------------------------------------------------------
                    Setting up $ISO mirrors for faster downloads
-------------------------------------------------------------------------
"
reflector -a 48 -c $ISO -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
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
sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
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
    mount -o ${MOUNT_OPTIONS},subvol=@home /dev/mapper/ROOT /mnt/home
    mount -o ${MOUNT_OPTIONS},subvol=@tmp /dev/mapper/ROOT /mnt/tmp
    mount -o ${MOUNT_OPTIONS},subvol=@.snapshots /dev/mapper/ROOT /mnt/.snapshots
    mount -o ${MOUNT_OPTIONS},subvol=@var /dev/mapper/ROOT /mnt/var
}

if [[ "${DISK}" =~ "nvme" ]]; then
    PARTITION_2=${DISK}p2
    PARTITION_3=${DISK}p3
else
    PARTITION_2=${DISK}2
    PARTITION_3=${DISK}3
fi

if [[ "${FS}" == "btrfs" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${PARTITION_2}
    mkfs.btrfs -L ROOT ${PARTITION_3} -f
    mount -t btrfs ${PARTITION_3} /mnt
elif [[ "${FS}" == "ext4" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${PARTITION_2}
    mkfs.ext4 -L ROOT ${PARTITION_3}
    mount -t ext4 ${PARTITION_3} /mnt
elif [[ "${FS}" == "luks" ]]; then
    mkfs.vfat -F32 -n "EFIBOOT" ${PARTITION_2}
# enter luks password to cryptsetup and format root partition
    echo -n "${LUKS_PASSWORD}" | cryptsetup -y -v luksFormat ${PARTITION_3} -
# open luks container and ROOT will be place holder 
    echo -n "${LUKS_PASSWORD}" | cryptsetup open ${PARTITION_3} ROOT -
# now format that container
    mkfs.btrfs -L ROOT /dev/mapper/ROOT
# create subvolumes for btrfs
    mount -t btrfs /dev/mapper/ROOT /mnt
    createsubvolumes       
    umount /mnt
# mount @ subvolume
    mount -o ${MOUNT_OPTIONS},subvol=@ /dev/mapper/ROOT /mnt
# make directories home, .snapshots, var, tmp
    mkdir -p /mnt/{home,var,tmp,.snapshots}
# mount subvolumes
    mountallsubvol
# store uuid of encrypted partition for grub
    echo ENCRYPTED_PARTITION_UUID=$(blkid -s UUID -o value ${PARTITION_3}) >> setup.conf
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
TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTAL_MEM -lt 8000000 ]]; then
    # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir /mnt/opt/swap # make a dir that we can apply NOCOW to to make it btrfs-friendly.
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
