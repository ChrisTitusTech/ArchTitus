#!/usr/bin/env bash
# shellcheck disable=SC1091,SC2001
# shellcheck source=./setup.conf

CONFIG_FILE=$(pwd)/setup.conf
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Missing file: setup.conf"
    exit 1
fi

make_boot() {
    mkfs.vfat -F32 -n "$1" "$2"
}

something_failed() {
    echo "Something failed. Exiting."
    exit 1
}

do_btrfs() {
    mkfs.btrfs -L "$1" "$2" -f
    mount -t btrfs "$2" "$MOUNTPOINT"

    title "Creating subvolumes and directories"
    for x in "${SUBVOLUMES[@]}"; do
        btrfs subvolume create "$MOUNTPOINT"/"${x}"
    done

    umount /mnt
    mount -o "$MOUNTOPTION",subvol=@ "$2" "$MOUNTPOINT"

    for z in "${SUBVOLUMES[@]:1}"; do
        w="$(echo "$z" | sed 's/@//g')"
        mkdir /mnt/"${w}"
        mount -o "$MOUNTOPTION",subvol="${z}" "$2" "$MOUNTPOINT"/"${w}"
    done
}

do_format() {
    mkfs."$FS" "$1" \
        "$([[ $FS == xfs || $FS == btrfs || $FS == reiserfs ]] && echo "-f")" \
        "$([[ $FS == vfat ]] && echo "-F32")" \
        "$([[ $TRIM -eq 1 && $FS == ext4 ]] && echo "-E discard -F")"

}

do_lvm() {
    while [[ "$i" -le "$LVM_PART_NUM" ]]; do
        if [[ "$i" -eq "$LVM_PART_NUM" ]]; then
            lvcreate -l 100%FREE "$LVM_VG" -n "${LVM_NAMES[$i]}"
            do_format /dev/"$LVM_VG"/"${LVM_NAMES[$i]}"
        else
            lvcreate -L "${LVM_SIZES[$i]}" "$LVM_VG" -n "${LVM_NAMES[$i]}"
            do_format /dev/"$LVM_VG"/"${LVM_NAMES[$i]}"
        fi
        i=$((i + 1))
    done
}

lvm_mount() {
    mount /dev/"$LVM_VG"/"${LVM_NAMES[0]}" "$MOUNTPOINT"/
    for x in "${LVM_NAMES[@]:1}"; do
        mkdir "$MOUNTPOINT"/"$x"
        mount /dev/"$LVM_VG"/"$x" "$MOUNTPOINT"/"$x"
    done
}

do_partition() {
    sgdisk -Z "$DISK"                                                     # zap all on disk
    sgdisk -a 2048 -o "$DISK"                                             # new gpt disk 2048 alignment
    sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:"BIOSBOOT" "$DISK" # partition 1 (BIOS Boot Partition)
    sgdisk -n 2::+300M --typecode=2:ef00 --change-name=2:"$BOOT" "$DISK"  # partition 2 (UEFI Boot Partition)
    sgdisk -n 3::-0 --typecode=3:8300 --change-name=3:"$ROOT" "$DISK"     # partition 3 (Root), default start, remaining
    if [[ "$UEFI" -eq 0 ]]; then
        sgdisk -A 1:set:2 "$DISK"
    fi
}



# format a partition from given list of filesystems

logo
title "Setting up mirrors for faster downloads"
install_pkg pacman-contrib reflector rsync gptfdisk btrfs-progs

sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup

# added https protocol for mirrors
reflector --age 48 --country "$ISO" -f 5 --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
mkdir /mnt &>/dev/null # Hiding error message if any

title "Partitioning disk"
if [[ "$SDD" -eq 1 ]]; then
    PART2=${DISK}p2
    PART3=${DISK}p3
else
    PART2=${DISK}2
    PART3=${DISK}3
fi


if [[ "$LAYOUT" -eq 1 ]]; then
    do_partition
    make_boot "$BOOT" "$PART2"
    do_btrfs "$ROOT" "$PART3"

elif [[ "$LVM" -eq 1 ]]; then
    do_partition
    make_boot "$BOOT" "$PART2"
    pvcreate "$PART3"
    vgcreate "$LVM_VG" "$PART3"
    do_lvm
    lvm_mount

elif [[ "$LUKS" -eq 1 ]]; then
    do_partition
    make_boot "$BOOT" "$PART2"
    # enter luks password to cryptsetup and format root partition
    echo -n "$LUKS_PASSWORD" | cryptsetup -y -v luksFormat "$PART3" -
    # open luks container and ROOT will be place holder
    echo -n "$LUKS_PASSWORD" | cryptsetup open "$PART3" "$ROOT" -
    pvcreate "$LUKS_PATH"
    vgcreate "$LVM_VG" "$LUKS_PATH"
    do_lvm
    lvm_mount
elif [[ "$LAYOUT" == 0 ]]; then
    modprobe dm-mod
    vgscan &>/dev/null
    vgchange -ay &>/dev/null
    # need to address boot partition
    # need to get root partition
    # need to format root partition
else
    something_failed
fi

# mount target
mkdir "$MOUNTPOINT"/boot
mount -t vfat -L EFIBOOT "$MOUNTPOINT"/boot/

if ! grep -qs '/mnt' /proc/mounts; then
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi

title "Arch Install on Main Drive"
# for test purposes
pacstrap "$MOUNTPOINT" base linux linux-firmware vim --needed --noconfirm
#pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
echo "keyserver hkp://keyserver.ubuntu.com" >>/mnt/etc/pacman.d/gnupg/gpg.conf

genfstab -U /mnt >>/mnt/etc/fstab

cp -R "${SCRIPT_DIR}" /mnt/root/ArchTitus
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

title "Checking for low memory systems <8G "

# TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
TOTALMEM=$(grep -i "memtotal" "/proc/meminfo" | grep -o '[[:digit:]]*')
if [[ $TOTALMEM -lt 8000000 ]]; then
    # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir -p /mnt/opt/swap  # make a dir that we can apply NOCOW to to make it btrfs-friendly.
    chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.
    dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 /mnt/opt/swap/swapfile # set permissions.
    chown root /mnt/opt/swap/swapfile
    mkswap /mnt/opt/swap/swapfile
    swapon /mnt/opt/swap/swapfile
    # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
    echo "/opt/swap/swapfile	none	swap	sw	0	0" >>/mnt/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
fi

title "SYSTEM READY FOR 1-setup.sh"
