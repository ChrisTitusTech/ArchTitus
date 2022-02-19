#!/usr/bin/env bash

# shellcheck disable=SC1091
# shellcheck source=./setup.conf

pacman -Sy --noconfirm
pacman -S --noconfirm --needed terminus-font
setfont ter-v22b
clear
# Find the name of the folder the scripts are in
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

copy_logs() {
    cp "$LOG" "$MOUNTPOINT"/var/log/archtitus.log
}

do_reboot () {
    if [[ "$LVM" -eq 1 || "$LUKS" -eq 1 ]]; then
        i=0
        while [[ "$i" -le "${#LVM_NAMES[@]}" ]]; do
            umount -l /dev/"$LVM_VG"/"${LVM_NAMES[$i]}"
        done
    fi
    umount -R "$MOUNTPOINT"/boot
    umount -R "$MOUNTPOINT"
    reboot
}

end() {
    REBOOT="true"
    copy_logs
    for (( i = 15; i >= 1; i-- )); do
        read -r -s -n 1 -t 1 -p "Rebooting in $i seconds... Press Esc key to abort or press R key to reboot now."$'\n' KEY
        CODE="$?"
        if [ "$CODE" != "0" ]; then
            continue
        fi
        if [[ "$KEY" == $'\e' ]]; then
            REBOOT="false"
            break
        elif [[ "$KEY" == "r" || "$KEY" == "R" ]]; then
            REBOOT="true"
            break
        fi
    done
    if [[ "$REBOOT" == "true" ]]; then
        do_reboot
    else
        echo "Reboot is aborted "
    fi
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
------------------------------------------------------------------------
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
end
