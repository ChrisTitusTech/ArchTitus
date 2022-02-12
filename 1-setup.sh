#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck source=./setup.conf

CONFIG_FILE=$(pwd)/setup.conf
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Missing file: setup.conf"
    exit 1
fi

title basic installations
install_pkg networkmanager dhclient reflector \
    rsync grub btrfs-progs arch-install-scripts \
    git pacman-contrib curl

title Network Setup
systemctl enable --now NetworkManager

install_xorg() {
    install_pkg "xorg xorg-server"
}

CPU="$(grep -c ^processor /proc/cpuinfo)"
echo -ne "
-------------------------------------------------------------------------
                    You have \"$CPU\" cores. And
			changing the makeflags for \"$CPU\" cores. As well as
				changing the compression settings.
-------------------------------------------------------------------------
"

TOTALMEM="$(grep -i "memtotal" "/proc/meminfo" | grep -o '[[:digit:]]*')"
if [[ $TOTALMEM -gt 8000000 ]]; then
    sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$CPU\"/g" /etc/makepkg.conf
    sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $CPU -z -)/g" /etc/makepkg.conf
fi

title Setup Language and set locale
# sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
echo "$LOCALE" | sed -i "s/\"//g" >>/etc/locale.gen

locale-gen
timedatectl --no-ask-password set-timezone "$TIMEZONE"
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="$LOCALE" LC_TIME="$LOCALE"

# Set keymaps
# echo "KEYMAP=$KEYMAP" >>/etc/vconsole.conf
localectl --no-ask-password set-keymap --no-convert "$KEYMAP"

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

#Add parallel downloading
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

# pacman -Sy --noconfirm
refresh_pacman

title Installing desktop
case "$DESKTOP" in
"default")
    # cat /root/ArchTitus/pkg-files/pacman-pkgs.txt | while read line
    while IFS= read -r LINE; do
        echo "INSTALLING: $LINE"
        install_pkg "$LINE"
    done </root/ArchTitus/pkg-files/pacman-pkgs.txt
    ;;
"gnome")
    install_xorg
    install_pkg "gnome gnome-extra gnome-software gnome-initial-setup gnome-tweak-tool gnome-power-manager"
    systemctl enable gdm.service
    ;;
"xfce")
    install_xorg
    install_pkg "xfce4 xfce4-goodies lightdm lightdm-gtk-greeter pavucontrol pulseaudio"
    systemctl enable lightdm.service
    ;;
"mate")
    install_xorg
    install_pkg "mate mate-extra lightdm lightdm-gtk-greeter"
    systemctl enable lightdm.service
    ;;
"lxqt")
    install_xorg
    install_pkg "lxqt breeze-icons sddm"
    systemctl enable sddm.service
    ;;
"openbox")
    install_xorg
    install_pkg "openbox obconf xterm lightdm lightdm-gtk-greeter"
    systemctl enable lightdm.service
    ;;
"awesome")
    install_xorg
    install_pkg "awesome vicious xterm lightdm lightdm-gtk-greeter"
    systemctl enable lightdm.service
    ;;
"minimal")
    install_xorg
    ;;
"i3")
    install_xorg
    install_pkg "i3-wm i3blocks i3lock i3status dmenu rxvt-unicode lightdm lightdm-gtk-greeter"
    systemctl enable lightdm.service
    ;;
"i3-gaps")
    install_xorg
    install_pkg "i3-gaps i3blocks i3lock i3status dmenu rxvt-unicode lightdm lightdm-gtk-greeter"
    systemctl enable lightdm.service
    ;;
"deepin")
    install_xorg
    install_pkg "deepin deepin-extra deepin-kwin"
    sed -i 's/^#greeter-session=.*/greeter-session=lightdm-deepin-greeter/' /etc/lightdm/lightdm.conf
    systemctl enable lightdm.service
    ;;
"budgie")
    install_xorg
    install_pkg "budgie-desktop budgie-desktop-view budgie-screensaver gnome-control-center network-manager-applet gnome"
    systemctl enable gdm.service
    ;;
*)
    something_failed
    ;;

esac

title Installing Microcode
# determine processor type and install microcode
PROC_TYPE="$(lscpu | grep "Vendor ID:" | awk '{print $3}')"

case "$PROC_TYPE" in
"GenuineIntel")
    echo "Installing Intel microcode"
    install_pkg intel-ucode
    ;;
"AuthenticAMD")
    echo "Installing AMD microcode"
    install_pkg amd-ucode
    ;;
*)
    something_failed
    ;;
esac

title Installing Graphics Drivers
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

title Adding User
if [ "$(whoami)" = "root" ]; then
    useradd -m -G wheel -s /bin/bash "$USERNAME"

    # use chpasswd to enter $USERNAME:$password
    echo "$USERNAME:$PASSWORD" | chpasswd
    cp -R /root/ArchTitus /home/"$USERNAME"/
    chown -R "$USERNAME": /home/"$USERNAME"/ArchTitus
    # enter $nameofmachine to /etc/hostname
    echo "$HOSTNAME" >>/etc/hostname
else
    echo "You are already a user proceed with aur installs"
fi

# Making sure to edit mkinitcpio conf if luks is selected
# add encrypt in mkinitcpio.conf before filesystems in hooks
if [[ "$LVM" -eq 1 ]]; then
    sed -i "/^HOOK/s/filesystems/${HOOKS[*]}/" /etc/mkinitcpio.conf
elif [[ "$LUKS" -eq 1 ]]; then
    sed -i "s/^HOOK.*/HOOKS=(${HOOKS[*]})/" /etc/mkinitcpio.conf
fi

if [[ -f "/etc/mkinitcpio.conf" ]];then
    # making mkinitcpio with linux kernel
    echo "Building initramfs"
    mkinitcpio -p linux
fi

title SYSTEM READY FOR 2-user.sh
