#!/bin/bash

# Find the name of the folder the scripts are in
set -a
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPTS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/scripts
CONFIGS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/configs
set +a
source_file() {
    if [[ -f "$1" ]]; then
        source "$1"
    else
        echo "ERROR! Missing file: $1"
        exit 0
    fi
}

logo() {
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
"
}

sequence() {
    . $SCRIPT_DIR/scripts/startup.sh # Dont need to log user password in plain text
    source_file $CONFIGS_DIR/setup.conf
    . $SCRIPT_DIR/scripts/0-preinstall.sh |& tee 0-preinstall.log
    (arch-chroot /mnt $HOME/ArchTitus/scripts/1-setup.sh) |& tee 1-setup.log
    if [[ ! $DESKTOP_ENV == server ]]; then
    (arch-chroot /mnt /usr/bin/runuser -u $USERNAME -- /home/$USERNAME/ArchTitus/scripts/2-user.sh) |& tee 2-user.log
    fi
    (arch-chroot /mnt $HOME/ArchTitus/scripts/3-post-setup.sh)|& tee 3-post-setup.log
    cp -v *.log /mnt/home/$USERNAME
}
clear
logo
echo -ne "
                Scripts are in directory named ArchTitus
"
sequence
logo
echo -ne "
                Done - Please Eject Install Media and Reboot
"
