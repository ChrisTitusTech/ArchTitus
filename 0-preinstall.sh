#!/usr/bin/env bash
# shellcheck disable=SC1091

logo

if [[ -f "$SCRIPT_DIR"/setup.conf ]]; then
	source setup.conf
else
	echo "missing file: setup.conf"
	exit 1
fi

title "Setting up mirrors for faster downloads"
install_pkg pacman-contrib reflector rsync gptfdisk btrfs-progs

sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

# added https protocol for mirrors
reflector --age 48 --country "$ISO" -f 5 --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt &>/dev/null # Hiding error message if any

title "Partitioning disk"
# disk prep
sgdisk -Z "$DISK" # zap all on disk
sgdisk -a 2048 -o "$DISK" # new gpt disk 2048 alignment
if [[ "$LAYOUT" ]]; then
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:"BIOSBOOT" "$DISK" # partition 1 (BIOS Boot Partition)
    sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:"EFIBOOT" "$DISK" # partition 2 (UEFI Boot Partition)
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:"ROOT" "$DISK" # partition 3 (Root), default start, remaining
    if [[ ! "$UEFI" ]]; then # Checking for bios system
        sgdisk -A 1:set:2 "$DISK"
    fi
    if [[ "$SDD" ]]; then
        PART2=${DISK}p2
        PART3=${DISK}p3
    else
        PART2=${DISK}2
        PART3=${DISK}3
    fi
    mkfs.vfat -F32 -n "EFIBOOT" "$PART2"
    mkfs.btrfs -L "ROOT" "$PART3" -f
    mount -t btrfs "$PART3" /mnt
    btrfs subvolume create /mnt/"${SUBVOLUMES[*]}"
    umount /mnt
    mount -o "$MOUNTOPTION",subvol="${SUBVOLUMES[*]}" "$PART3" /mnt
else
    modprobe dm-mod
    vgscan &>/dev/null
    vgchange -ay &>/dev/null

fi


# check if layout is default
# if [[ "$LAYOUT" == "default" ]]; then
#     # check if disk is already formatted
#     if [[ "$(lsblk -o NAME,FSTYPE | grep"$DISK" | awk '{print $2}')" == "btrfs" ]]; then
#         echo "Disk already formatted"
#     else
#         # format disk
#         btrfs device scan
#         btrfs filesystem label "$DISK" "$LABEL"
#     fi
# else
#     # check if disk is already formatted
#     if [[ "$(lsblk -o NAME,FSTYPE | grep "$DISK" | awk '{print $2}')" == "btrfs" ]]; then
#         echo "Disk already formatted"
#     else
#         # format disk
#         btrfs device scan
#         btrfs filesystem label "$DISK" "$LABEL"
#         # create partitions
#         parted -s "$DISK" mklabel gpt
#         parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
#         parted -s "$DISK" set 1 boot on
#         parted -s "$DISK" mkpart primary 513MiB 100%
#         parted -s "$DISK" set 2 lvm on
#         parted -s "$DISK" print
#         # create volume group
#         pvcreate "$DISK"2
#         vgcreate "$VG" "$DISK"2
#         # create logical volumes
#         lvcreate -L "$LV_ROOT" -n "$LV_ROOT" "$VG"
#         lvcreate -L "$LV_HOME" -n "$LV_HOME" "$VG"
#         lvcreate -L "$LV_SWAP" -n "$LV_SWAP" "$VG"
#         # format partitions
#         mkfs.fat -F32 "$DISK"1
#         mkfs.btrfs -L "$LABEL" "$DISK"2
#         mkswap "$DISK"3
#         # mount partitions
#         mount "$DISK"2 /mnt
#         mkdir /
# disk prep
# sgdisk -Z ${DISK} # zap all on disk
# sgdisk -a 2048 -o ${DISK} # new gpt disk 2048 alignment

# # create partitions
# sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:'BIOSBOOT' ${DISK} # partition 1 (BIOS Boot Partition)
# sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:'EFIBOOT' ${DISK} # partition 2 (UEFI Boot Partition)
# sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:'ROOT' ${DISK} # partition 3 (Root), default start, remaining
# if [[ ! -d "/sys/firmware/efi" ]]; then # Checking for bios system
#     sgdisk -A 1:set:2 ${DISK}
# fi
# make filesystems
echo -ne "
-------------------------------------------------------------------------
                    Creating Filesystems
-------------------------------------------------------------------------
"
# createsubvolumes () {
#     btrfs subvolume create /mnt/@
#     btrfs subvolume create /mnt/@home
#     btrfs subvolume create /mnt/@var
#     btrfs subvolume create /mnt/@tmp
#     btrfs subvolume create /mnt/@.snapshots
# }

# mountallsubvol () {
#     mount -o ${mountoptions},subvol=@home /dev/mapper/ROOT /mnt/home
#     mount -o ${mountoptions},subvol=@tmp /dev/mapper/ROOT /mnt/tmp
#     mount -o ${mountoptions},subvol=@.snapshots /dev/mapper/ROOT /mnt/.snapshots
#     mount -o ${mountoptions},subvol=@var /dev/mapper/ROOT /mnt/var
# }

# if [[ "${DISK}" =~ "nvme" ]]; then
#     partition2=${DISK}p2
#     partition3=${DISK}p3
# else
#     partition2=${DISK}2
#     partition3=${DISK}3
# fi

# if [[ "${FS}" == "btrfs" ]]; then
#     mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
#     mkfs.btrfs -L ROOT ${partition3} -f
#     mount -t btrfs ${partition3} /mnt
# elif [[ "${FS}" == "ext4" ]]; then
#     mkfs.vfat -F32 -n "EFIBOOT" ${partition2}
#     mkfs.ext4 -L ROOT ${partition3}
#     mount -t ext4 "${partition3}" /mnt
# elif [[ "${FS}" == "luks" ]]; then
#     mkfs.vfat -F32 -n "EFIBOOT" "${partition2}"
# # enter luks password to cryptsetup and format root partition
#     echo -n "${luks_password}" | cryptsetup -y -v luksFormat "${partition3}" -
# # open luks container and ROOT will be place holder 
#     echo -n "${luks_password}" | cryptsetup open "${partition3} "ROOT -
# # now format that container
#     mkfs.btrfs -L ROOT /dev/mapper/ROOT
# # create subvolumes for btrfs
#     mount -t btrfs /dev/mapper/ROOT /mnt
#     createsubvolumes       
#     umount /mnt
# # mount @ subvolume
#     mount -o "${mountoptions}",subvol=@ /dev/mapper/ROOT /mnt
# # make directories home, .snapshots, var, tmp
#     mkdir -p /mnt/{home,var,tmp,.snapshots}
# # mount subvolumes
#     mountallsubvol
# # store uuid of encrypted partition for grub
#     echo encryped_partition_uuid="$(blkid -s UUID -o value "${partition3}")" >> setup.conf
# fi

# checking if user selected btrfs
# if [[ ${FS} =~ "btrfs" ]]; then
# ls /mnt | xargs btrfs subvolume delete
# btrfs subvolume create /mnt/@
# umount /mnt
# mount -t btrfs -o subvol=@ -L ROOT /mnt
# fi

# mount target
mkdir /mnt/boot
mkdir /mnt/boot/efi
mount -t vfat -L EFIBOOT /mnt/boot/

# if ! grep -qs '/mnt' /proc/mounts; then
#     echo "Drive is not mounted can not continue"
#     echo "Rebooting in 3 Seconds ..." && sleep 1
#     echo "Rebooting in 2 Seconds ..." && sleep 1
#     echo "Rebooting in 1 Second ..." && sleep 1
#     reboot now
# fi
# echo -ne "
# -------------------------------------------------------------------------
#                     Arch Install on Main Drive
# -------------------------------------------------------------------------
# "
# pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
# echo "keyserver hkp://keyserver.ubuntu.com" >> /mnt/etc/pacman.d/gnupg/gpg.conf
# # check pacstrap installed or not

# cp -R "${SCRIPT_DIR}" /mnt/root/ArchTitus
# cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
# echo -ne "
# -------------------------------------------------------------------------
#                     GRUB BIOS Bootloader Install & Check
# -------------------------------------------------------------------------
# "
# # if [[ ! -d "/sys/firmware/efi" ]]; then
# #     grub-install --boot-directory=/mnt/boot "${DISK}"
# # fi
# echo -ne "
# -------------------------------------------------------------------------
#                     Checking for low memory systems <8G
# -------------------------------------------------------------------------
# "
# # TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
# TOTALMEM=$(grep -i "memtotal" "/proc/meminfo" | grep -o '[[:digit:]]*')
# if [[  $TOTALMEM -lt 8000000 ]]; then
#     # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
#     mkdir /mnt/opt/swap # make a dir that we can apply NOCOW to to make it btrfs-friendly.
#     chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.
#     dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
#     chmod 600 /mnt/opt/swap/swapfile # set permissions.
#     chown root /mnt/opt/swap/swapfile
#     mkswap /mnt/opt/swap/swapfile
#     swapon /mnt/opt/swap/swapfile
#     # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
#     echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
# fi
# echo -ne "
-------------------------------------------------------------------------
                    SYSTEM READY FOR 1-setup.sh
-------------------------------------------------------------------------
"
