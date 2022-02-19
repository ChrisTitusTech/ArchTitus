#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck source=./setup.conf
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

CONFIG_FILE="$SCRIPT_DIR"/setup.conf
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "ERROR! Missing file: setup.conf"
    exit 0
fi
logo
echo "basic installations"
install_pkg networkmanager dhclient reflector \
    rsync arch-install-scripts \
    git pacman-contrib curl efibootmgr

install_xorg() {
    install_pkg xorg xorg-server xorg-xinit
}

TOTALMEM="$(grep -i "memtotal" "/proc/meminfo" | grep -o '[[:digit:]]*')"
CPU="$(grep -c ^processor /proc/cpuinfo)"
if [[ $TOTALMEM -gt 8000000 ]]; then
    echo -ne "
-------------------------------------------------------------------------
                    You have \"$CPU\" cores. And
			changing the makeflags for \"$CPU\" cores. As well as
				changing the compression settings.
-------------------------------------------------------------------------
"
    sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$CPU\"/g" /etc/makepkg.conf
    sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $CPU -z -)/g" /etc/makepkg.conf
fi

echo "Setup Language and set locale"
# sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
echo "$LOCALE" | sed -i "s/\"//g" >>/etc/locale.gen

locale-gen
timedatectl --no-ask-password set-timezone "$TIMEZONE"
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="$LOCALE" LC_TIME="$LOCALE"
localectl --no-ask-password set-keymap --no-convert "$KEYMAP"

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

#Add parallel downloading
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

# pacman -Sy --noconfirm
refresh_pacman

echo "Installing $DESKTOP"
case "$DESKTOP" in
"default")
    while IFS= read -r LINE; do
        echo "INSTALLING: $LINE"
        install_pkg "$LINE"
    done </root/ArchTitus/pkg-files/pacman-pkgs.txt
    systemctl enable sddm.service
    ;;
"gnome")
    install_xorg
    install_pkg gnome gnome-extra gnome-software gnome-initial-setup gnome-tweak-tool gnome-power-manager
    systemctl enable gdm.service
    ;;
"xfce")
    install_xorg
    install_pkg xfce4 xfce4-goodies lightdm lightdm-gtk-greeter pavucontrol pulseaudio
    systemctl enable lightdm.service
    ;;
"mate")
    install_xorg
    install_pkg mate mate-extra lightdm lightdm-gtk-greeter
    systemctl enable lightdm.service
    ;;
"lxqt")
    install_xorg
    install_pkg lxqt breeze-icons sddm
    systemctl enable sddm.service
    ;;
"openbox")
    install_xorg
    install_pkg openbox obconf xterm lightdm lightdm-gtk-greeter
    systemctl enable lightdm.service
    ;;
"awesome")
    install_xorg
    install_pkg awesome vicious xterm lightdm lightdm-gtk-greeter
    systemctl enable lightdm.service
    ;;
"minimal")
    install_xorg
    ;;
"i3")
    install_xorg
    install_pkg i3-wm i3blocks i3lock i3status dmenu rxvt-unicode lightdm lightdm-gtk-greeter
    systemctl enable lightdm.service
    ;;
"i3-gaps")
    install_xorg
    install_pkg i3-gaps i3blocks i3lock i3status dmenu rxvt-unicode lightdm lightdm-gtk-greeter
    systemctl enable lightdm.service
    ;;
"deepin")
    install_xorg
    install_pkg deepin deepin-extra deepin-kwin
    sed -i 's/^#greeter-session=.*/greeter-session=lightdm-deepin-greeter/' /etc/lightdm/lightdm.conf
    systemctl enable lightdm.service
    ;;
"budgie")
    install_xorg
    install_pkg budgie-desktop budgie-desktop-view budgie-screensaver gnome-control-center network-manager-applet gnome
    systemctl enable gdm.service
    ;;
*)
    something_failed
    ;;

esac

echo "Installing Microcode"
# determine processor type and install microcode
PROC_TYPE="$(lscpu | grep "Vendor ID:" | awk '{print $3}' | head -1)"

case "$PROC_TYPE" in
"GenuineIntel")
    echo "Installing Intel microcode"
    install_pkg intel-ucode
    IMG=intel-ucode.img
    ;;
"AuthenticAMD")
    echo "Installing AMD microcode"
    install_pkg amd-ucode
    IMG=amd-ucode.img
    ;;
*)
    something_failed
    ;;
esac

echo "Installing Graphics Drivers"
# Graphics Drivers find and install
if [[ "$(lspci | grep -E '(NVIDIA|GeForce)' -c)" -gt "0" ]]; then
    install_pkg "nvidia nvidia-utils libglvnd"
elif [[ "$(lspci | grep -E '(Radeon|AMD)' -c)" -gt "0" ]]; then
    install_pkg "xf86-video-amdgpu mesa-libgl mesa-vdpau libvdpau-va-gl"
elif [[ "$(lspci | grep -E '(Integrated Graphics Controller|Intel Corporation UHD)' -c)" -gt "0" ]]; then
    # install_pkg "libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa"
    install_pkg "xf86-video-intel vulkan-radeon mesa-libgl mesa-vdpau libvdpau-va-gl"
else
    echo "No graphics card found!"
fi

ENCRYPT_UUID=$(blkid -s UUID -o value "$PART2")
PART_UUID=$(blkid -s PARTUUID -o value "$PART2")

case "$BOOTLOADER" in
grub)
    echo "Installing GRUB"
    install_pkg grub os-prober
    if [[ "$LUKS" -eq 1 ]]; then
        echo "Installing GRUB for LUKS"
        sed -i -e 's/GRUB_CMDLINE_LINUX="\(.\+\)"/GRUB_CMDLINE_LINUX="\1 cryptdevice=UUID='"${ENCRYPT_UUID}"':luks"/g' -e 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=UUID='"${ENCRYPT_UUID}"':luks"/g' /etc/default/grub
    fi
    if [[ "$UEFI" -eq 1 ]]; then
        grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=ArchTitus
    else
        grub-install --target=i386-pc "$DISK"
    fi
    grub-mkconfig -o /boot/grub/grub.cfg
    ;;
systemd)
    if [[ "$UEFI" -eq 1 ]]; then
        echo "Installing systemd-boot"
        bootctl --path=/boot install
        if [[ $LUKS -eq 1 ]]; then
            echo -e "title\tArchTitus\nlinux\t/vmlinuz-linux\ninitrd\t/initramfs-linux.img\ninitrd\t/$IMG\noptions\tcryptdevice=UUID=$ENCRYPT_UUID:luks root=/dev/$LVM_VG/${LVM_NAMES[0]} rw" >/boot/loader/entries/arch.conf
        elif [[ $LVM -eq 1 ]]; then
            echo -e "title\tArchTitus\nlinux\t/vmlinuz-linux\ninitrd\t/initramfs-linux.img\ninitrd\t/$IMG\noptions\troot=/dev/$LVM_VG/${LVM_NAMES[0]} rw" >/boot/loader/entries/arch.conf
        else
            echo -e "title\tArchTitus\nlinux\t/vmlinuz-linux\ninitrd\t/initramfs-linux.img\ninitrd\t/$IMG\noptions\troot=PARTUUID=$PART_UUID rw" >/boot/loader/entries/arch.conf
        fi
        echo -e "default  arch\ntimeout\t5" >/boot/loader/loader.conf
    else
        echo "ERROR! Systemd-boot is not supported for BIOS systems"
        exit 0
    fi
    ;;
uefi)
    if [[ "$UEFI" -eq 1 ]]; then
        echo "Installing efistub"
        install_pkg efibootmgr
        if [[ "$LUKS" -eq 1 ]]; then
            efibootmgr --disk "$DISK" --part 1 --create --label "ArchTitus-Fallback" --loader "/vmlinuz-linux" --unicode "cryptdevice=PARTUUID=$PART_UUID:luks:allow-discards root=/dev/$LVM_VG/${LVM_NAMES[0]} rw initrd=\\$IMG initrd=\initramfs-linux-fallback.img"
            efibootmgr --disk "$DISK" --part 1 --create --label "ArchTitus" --loader "/vmlinuz-linux" --unicode "cryptdevice=PARTUUID=$PART_UUID:luks:allow-discards root=/dev/$LVM_VG/${LVM_NAMES[0]} rw initrd=\\$IMG initrd=\initramfs-linux.img"
        elif [[ "$LVM" -eq 1 ]]; then
            efibootmgr --disk "$DISK" --part 1 --create --label "ArchTitus-Fallback" --loader "/vmlinuz-linux" --unicode "root=/dev/$LVM_VG/${LVM_NAMES[0]} rw initrd=\\$IMG initrd=\initramfs-linux-fallback.img"
            efibootmgr --disk "$DISK" --part 1 --create --label "ArchTitus" --loader "/vmlinuz-linux" --unicode "root=/dev/$LVM_VG/${LVM_NAMES[0]} rw initrd=\\$IMG initrd=\initramfs-linux.img"
        else
            efibootmgr --disk "$DISK" --part 1 --create --label "ArchTitus-Fallback" --loader "/vmlinuz-linux" --unicode "root=PARTUUID=$PART_UUID rw initrd=\\$IMG initrd=\initramfs-linux-fallback.img"
            efibootmgr --disk "$DISK" --part 1 --create --label "ArchTitus" --loader "/vmlinuz-linux" --unicode "root=PARTUUID=$PART_UUID rw initrd=\\$IMG initrd=\initramfs-linux.img"
        fi
    else
        echo "ERROR! efistub is not supported for BIOS systems"
        exit 0
    fi
    ;;
none)
    echo "Skipping bootloader installation"
    ;;
*)
    something_failed
    ;;
esac

echo "Adding User and hostname"
if [ "$(id -u)" -eq "0" ]; then
    if [[ "$LAYOUT" -eq 1 ]]; then
        groupadd libvirt
        useradd -m -G wheel,libvirt -s /bin/bash "$USERNAME"
    else
        useradd -m -G wheel -s /bin/bash "$USERNAME"
    fi
    echo "$USERNAME:$PASSWORD" | chpasswd
    cp -R /root/ArchTitus /home/"$USERNAME"/
    chown -R "$USERNAME": /home/"$USERNAME"/ArchTitus
    echo "$HOSTNAME" >>/etc/hostname
else
    echo "You are already a user proceed with aur installs"
fi

# Making sure to edit mkinitcpio conf if luks is selected
# add encrypt in mkinitcpio.conf before filesystems in hooks

if [[ "$LVM" -eq 1 ]]; then
    echo "LVM hooks added"
    sed -i "/^HOOK/s/filesystems/${HOOKS[*]}/" /etc/mkinitcpio.conf
elif [[ "$LUKS" -eq 1 ]]; then
    echo "LUKS hooks added"
    sed -i "s/^HOOK.*/HOOKS=(${HOOKS[*]})/" /etc/mkinitcpio.conf
elif [[ "$LAYOUT" -eq 1 ]]; then
    echo "Btrfs module added"
    sed -i '/^MODULES=/s/(/(btrfs/' /etc/mkinitcpio.conf
fi

if [[ -f "/etc/mkinitcpio.conf" ]]; then
    # making mkinitcpio with linux kernel
    echo "Building initramfs"
    mkinitcpio -p linux
fi

title "System ready for 2-user.sh"
