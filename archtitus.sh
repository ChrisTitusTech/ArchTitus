#!/bin/bash
#github-action genshdoc
# shellcheck disable=SC1090,SC1091

# Find the name of the folder the scripts are in
set -a
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
SCRIPTS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/scripts
CONFIGS_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/configs
set +a

CONFIG_FILE="$SCRIPT_DIR"/configs/setup.conf
LOG_FILE="$SCRIPT_DIR"/configs/main.log

[[ -f "$LOG_FILE" ]] && rm -f "$LOG_FILE"

source_file() {
    if [[ -f "$1" ]]; then
        source "$1"
    else
        echo "ERROR! Missing file: $1"
        exit 0
    fi
}

end() {
    echo "Copying logs"
    if [[ "$(find /mnt/var/log -type d | wc -l)" -ne 0 ]]; then
        cp -v "$LOG_FILE" /mnt/var/log/ArchTitus.log
    else
        echo -ne "ERROR! Log directory not found"
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
    . "$SCRIPT_DIR"/scripts/0-preinstall.sh
    arch-chroot /mnt "$HOME"/ArchTitus/scripts/1-setup.sh
    if [[ ! "$DESKTOP_ENV" == server ]]; then
    arch-chroot /mnt /usr/bin/runuser -u "$USERNAME" -- /home/"$USERNAME"/ArchTitus/scripts/2-user.sh
    fi
    arch-chroot /mnt "$HOME"/ArchTitus/scripts/3-post-setup.sh
}

clear
logo
echo -ne "
                Scripts are in directory named ArchTitus
"
. "$SCRIPT_DIR"/scripts/startup.sh
source_file "$CONFIG_FILE"
sequence |& tee "$LOG_FILE"
logo
echo -ne "
                Done - Please Eject Install Media and Reboot
"
end