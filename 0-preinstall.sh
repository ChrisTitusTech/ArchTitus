#!/usr/bin/env bash

# shellcheck disable=SC1091,SC2001
# shellcheck source=./setup.conf
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

CONFIG_FILE="$SCRIPT_DIR"/setup.conf
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "ERROR! Missing file: setup.conf"
    exit 0
fi

make_boot() {
    if [[ "$UEFI" -eq 1 ]]; then
        mkfs.vfat -F32 -n "$BOOT" "$PART1"
    fi
}

do_btrfs() {
    mkfs.btrfs -L "$1" "$2" -f
    mount -t btrfs "$2" "$MOUNTPOINT"

    echo "Creating subvolumes and directories"
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

# list of packages to install
PACKAGES=()

do_format() {
    case "$FS" in
    "xfs")
        install_pkg xfsprogs
        PACKAGES+=("xfsprogs")
        mkfs.xfs -f -L "$ROOT" "$1"
        ;;
    "btrfs")
        install_pkg btrfs-progs
        PACKAGES+=("btrfs-progs")
        mkfs.btrfs -L "$ROOT" "$1" -f
        ;;
    "ext4")
        mkfs.ext4 -E discard -F -L "$ROOT" "$1"
        ;;
    "vfat")
        mkfs.vfat -F32 "$1"
        ;;
    "f2fs")
        install_pkg f2fs-tools
        PACKAGES+=("f2fs-tools")
        mkfs.f2fs -l "$ROOT" -O extra_attr,inode_checksum,sb_checksum "$1"
        ;;
    "ext2")
        mkfs.ext2 -L "$ROOT" "$1"
        ;;
    "ext3")
        mkfs.ext3 -L "$ROOT" "$1"
        ;;
    "jfs")
        install_pkg jfsutils
        PACKAGES+=("jfsutils")
        mkfs.jfs -L "$ROOT" "$1"
        ;;
    "nilfs2")
        install_pkg nilfs-utils
        PACKAGES+=("nilfs-utils")
        mkfs.nilfs2 -L "$ROOT" "$1"
        ;;
    "ntfs")
        install_pkg ntfs-3g
        PACKAGES+=("ntfs-3g")
        mkfs.ntfs -Q -L "$ROOT" "$1"
        ;;
    *)
        something_failed
        ;;
    esac

}

do_lvm() {
    i=0
    while [[ "$i" -le "${#LVM_PART_NUM[@]}" ]]; do
        if [[ "${#LVM_PART_NUM[@]}" -eq "1" ]]; then
            lvcreate --extents 100%FREE "$LVM_VG" --name "${LVM_NAMES[$i]}"
        else
            lvcreate --size "${LVM_SIZES[$i]}" "$LVM_VG" --name "${LVM_NAMES[$i]}"
        fi
        i=$((i + 1))
    done
}

mount_lvm() {
    vgchange -ay &>/dev/null
    i=0
    while [[ "$i" -le "${#LVM_PART_NUM[@]}" ]]; do
        lvchange -ay /dev/"$LVM_VG"/"${LVM_NAMES[$i]}" &>/dev/null
        do_format /dev/"$LVM_VG"/"${LVM_NAMES[$i]}"

        i=$((i + 1))
    done
    mount -t "$FS" /dev/"$LVM_VG"/"${LVM_NAMES[0]}" "$MOUNTPOINT"
    for x in "${LVM_NAMES[@]:1}"; do
        mkdir "$MOUNTPOINT"/"$x"
        mount -t "$FS" /dev/"$LVM_VG"/"$x" "$MOUNTPOINT"/"$x"
    done
}

prep_disk() {
    wipefs -a -f "$DISK"      # wipe any file system
    sgdisk -Z "$DISK"         # zap all on disk
    sgdisk -a 2048 -o "$DISK" # new gpt disk 2048 alignment
}

do_partition() {
    prep_disk
    if [[ "$UEFI" -eq 1 ]]; then
        sgdisk -n 1::+300M --typecode=1:ef00 --change-name=1:"$BOOT" "$DISK" # partition 1 (UEFI Boot Partition)
        sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:"$ROOT" "$DISK"    # partition 2 (Root), default start, remaining
    else
        sgdisk -n 1::+1M --typecode=1:ef02 --change-name=1:"BIOSBOOT" "$DISK"
        sgdisk -n 2::-0 --typecode=2:8300 --change-name=2:"$ROOT" "$DISK"

    fi
}

mount_boot() {
    if [[ "$UEFI" -eq "1" ]]; then
        mkdir "$MOUNTPOINT"/boot
        mount -t vfat -L EFIBOOT "$MOUNTPOINT"/boot/
    fi
}

logo
title "Preinstall setup"
echo "Setting up mirrors for faster downloads"
install_pkg pacman-contrib reflector rsync gptfdisk

sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

if [[ ! -f /etc/pacman.d/mirrorlist.backup ]]; then
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
fi

# added https protocol for mirrors
reflector --age 48 --country "$ISO" -f 5 --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
mkdir "$MOUNTPOINT" &>/dev/null # Hiding error message if any

echo "File system setup"
if [[ "$SDD" -eq "1" ]]; then
    PART1=${DISK}p1
    PART2=${DISK}p2
else
    PART1=${DISK}1
    PART2=${DISK}2
fi

set_option "PART2" "$PART2"

if [[ "$LAYOUT" -eq "1" ]]; then
    do_partition
    make_boot
    do_btrfs "$ROOT" "$PART2"
    mount_boot

elif [[ "$LVM" -eq "1" ]]; then
    PACKAGES+=("lvm2")
    do_partition
    sgdisk --typecode=2:8e00 "$DISK"
    partprobe "$DISK"
    make_boot
    pvcreate "$PART2"
    vgcreate "$LVM_VG" "$PART2"
    do_lvm
    mount_lvm
    mount_boot
    set_option "HOOKS" "(lvm2 filesystems)"

elif [[ "$LUKS" -eq "1" ]]; then
    PACKAGES+=("cryptsetup" "lvm2")
    do_partition
    make_boot
    echo -n "$LUKS_PASSWORD" | cryptsetup -y -v luksFormat "$PART2" -
    # $LUKS_PATH "/dev/mapper/luks"
    echo -n "$LUKS_PASSWORD" | cryptsetup open "$PART2" luks -
    pvcreate "$LUKS_PATH"
    vgcreate "$LVM_VG" "$LUKS_PATH"
    do_lvm
    mount_lvm
    mount_boot
    # set_option "ENCRYP_PART" "$_PART_UUID"
    # HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)
    set_option "HOOKS" "(base udev autodetect keyboard keymap consolefont modconf block lvm2 encrypt filesystems fsck)"

elif [[ "$LAYOUT" -eq "0" ]]; then
    modprobe dm-mod
    vgscan &>/dev/null
    vgchange -ay &>/dev/null
    do_format "$ROOT_PARTITION"
    mount "$ROOT_PARTITION" "$MOUNTPOINT"
    if [[ "$UEFI" -eq 1 ]]; then
        mkfs.vfat -F32 -n "$BOOT" "$BOOT_PARTITION"
        mount_boot
    fi

else
    something_failed
fi

if [[ "$(grep -E "$MOUNTPOINT" /proc/mounts -c)" -eq "0" ]]; then
    echo "Drive is not mounted can not continue"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    # reboot now
    exit 0
fi

echo "Arch Install on Main Drive"
# for test purposes
# pacstrap "$MOUNTPOINT" base linux vim --needed --noconfirm
pacstrap "$MOUNTPOINT" base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt "${PACKAGES[@]}" --noconfirm --needed
echo "keyserver hkp://keyserver.ubuntu.com" >>"$MOUNTPOINT"/etc/pacman.d/gnupg/gpg.conf

genfstab -U "$MOUNTPOINT" >>"$MOUNTPOINT"/etc/fstab

cp -R "$SCRIPT_DIR" "$MOUNTPOINT"/root/ArchTitus
cp /etc/pacman.d/mirrorlist "$MOUNTPOINT"/etc/pacman.d/mirrorlist

# TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
TOTALMEM="$(grep -i "memtotal" "/proc/meminfo" | grep -o '[[:digit:]]*')"
if [[ $TOTALMEM -lt 8000000 ]]; then
    echo "Checking for low memory systems <8G "
    # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
    mkdir -p "$MOUNTPOINT"/opt/swap  # make a dir that we can apply NOCOW to to make it btrfs-friendly.
    chattr +C "$MOUNTPOINT"/opt/swap # apply NOCOW, btrfs needs that.
    dd if=/dev/zero of="$MOUNTPOINT"/opt/swap/swapfile bs=1M count=2048 status=progress
    chmod 600 "$MOUNTPOINT"/opt/swap/swapfile # set permissions.
    chown root "$MOUNTPOINT"/opt/swap/swapfile
    mkswap "$MOUNTPOINT"/opt/swap/swapfile
    swapon "$MOUNTPOINT"/opt/swap/swapfile
    # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
    echo -e "/opt/swap/swapfile\tnone     \tswap     \tsw\t0 0" >>"$MOUNTPOINT"/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
fi

title "System ready for 1-setup.sh"
