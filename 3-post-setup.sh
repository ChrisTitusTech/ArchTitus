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

install_grub_theme() {
    if [[ "$GRUBTHEME" =~ "None" ]]; then
        echo "No grub theme selected. Skipping..."
    else
        echo -e "Installing $GRUBTHEME Grub theme..."
        git clone https://github.com/ChrisTitusTech/Top-5-Bootloader-Themes tmp
        echo -e "Creating the theme directory..."
        mkdir -p "$THEMEDIR"/"$GRUBTHEME"
        echo -e "Copying the theme..."
        cd "$HOME"/tmp/themes || exit 0
        cp -a "$GRUBTHEME"/* "$THEMEDIR"/"$GRUBTHEME"
        echo -e "Backing up Grub config..."
        cp -an /etc/default/grub /etc/default/grub.bak
        echo -e "Setting the theme as the default..."
        grep "GRUB_THEME=" /etc/default/grub >/dev/null 2>&1 && sed -i '/GRUB_THEME=/d' /etc/default/grub
        echo "GRUB_THEME=\"$THEMEDIR/$GRUBTHEME/theme.txt\"" >>/etc/default/grub
        echo -e "Updating grub..."
        grub-mkconfig -o /boot/grub/grub.cfg
        echo -e "All set!"
    fi
}


logo
title "Post Install and cleaning"
if [[ "$BOOTLOADER" =~ "grub" ]]; then
    install_grub_theme
fi

if [[ "$LAYOUT" -eq 1 || "$DESKTOP" =~ "lxqt" ]]; then
    echo "Setting up SDDM Theme"
    cat <<EOF >/etc/sddm.conf
[Theme]
Current=Nordic
EOF
fi

echo "Enabling Essential Services"
systemctl enable cups.service
systemctl enable cronie.service
ntpd -qg
systemctl enable ntpd.service
systemctl stop dhcpcd.service
systemctl disable dhcpcd.service
systemctl enable NetworkManager.service
systemctl enable bluetooth

echo "Cleaning"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

rm -r /root/ArchTitus
rm -r /home/"$USERNAME"/ArchTitus

# Replace in the same state
cd "$(pwd)" || exit 0
