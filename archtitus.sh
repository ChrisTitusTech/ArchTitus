#!/usr/bin/env bash
# shellcheck disable=SC1091
# shellcheck source=./setup.conf

# Find the name of the folder the scripts are in
pacman -Sy --noconfirm
pacman -S --noconfirm --needed terminus-font
setfont ter-v22b
clear
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

CONFIG_FILE="$SCRIPT_DIR"/setup.conf

LOG="${SCRIPT_DIR}/main.log"
[[ -f "$LOG" ]] && rm -f "$LOG"

logo() {
    echo -ne "
------------------------------------------------------------------------

 █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
"
}

sequence() {
    echo -ne "Starting ArchTitus...\n"
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        echo "ERROR! Missing file: setup.conf"
        exit 1
    fi
    bash 0-preinstall.sh
    arch-chroot /mnt /root/ArchTitus/1-setup.sh
    arch-chroot /mnt /usr/bin/runuser -u "$USERNAME" -- /home/"$USERNAME"/ArchTitus/2-user.sh
    arch-chroot /mnt /root/ArchTitus/3-post-setup.sh
    logo
    echo -ne "
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------
                Done - Please Eject Install Media and Reboot
"
}
logo
echo -ne "
-------------------------------------------------------------------------
                    Automated Arch Linux Installer
-------------------------------------------------------------------------
                Scripts are in directory named ArchTitus
"
bash startup.sh
sequence |& tee "$LOG"
