#!/usr/bin/env bash

# shellcheck disable=SC2207,SC2120

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Set up a config file
CONFIG_FILE="$SCRIPT_DIR"/setup.conf

[[ -f "$CONFIG_FILE" ]] && rm -f "$CONFIG_FILE" >/dev/null 2>&1

set_option() {
    if grep -Eq "^${1}.*" "$CONFIG_FILE"; then
        sed -i -e "/^${1}.*/d" "$CONFIG_FILE"
    fi
    echo "${1}=${2}" >>"$CONFIG_FILE"
}

# Adding global functions and variables to use in this script

check_root() {
    if [[ "$(id -u)" != "0" ]]; then
        echo -ne "ERROR! This script must be running under the 'root' user!\n"
        exit 0
    fi
}

check_docker() {
    if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r; then
        echo -ne "ERROR! Docker container not supported (at the moment)\n"
        exit 0
    elif [[ -f /.dockerenv ]]; then
        echo -ne "ERROR! Docker container not supported (at the moment)\n"
        exit 0
    fi
}

check_arch() {
    if [[ ! -e /etc/arch-release ]]; then
        echo -ne "ERROR! This script must be run in Arch Linux!\n"
        exit 0
    fi
}

check_pacman() {
    if [[ -f /var/lib/pacman/db.lck ]]; then
        echo "ERROR! Pacman is blocked."
        echo -ne "If not running remove /var/lib/pacman/db.lck.\n"
        exit 0
    fi
}

connection_test() {
    ping -q -w 1 -c 1 "$(ip r | grep default | awk 'NR==1 {print $3}')" &>/dev/null && return 1 || return 0
}

do_curl() {
    _ISO=$(curl --fail https://ifconfig.co/country-iso)
    set_option "ISO" "$_ISO"
}

set_ntp() {
    timedatectl set-ntp true
}

efi_check() {
    if [[ -d "/sys/firmware/efi/" ]]; then
        if (mount | grep /sys/firmware/efi/efivars); then
            (mount -t efivarfs efivarfs /sys/firmware/efi/efivars) >/dev/null 2>&1
        fi
        set_option "UEFI" 1
    else
        set_option "UEFI" 0
    fi
}

set_btrfs() {
    echo "Please enter your btrfs subvolumes separated by space"
    echo "usualy they start with @."
    echo "[like @home, default are @home, @var, @tmp, @.snapshots]"
    echo " "
    read -r -p "press enter to use default: " -a ARR
    if [[ -z "${ARR[*]}" ]]; then
        set_option "SUBVOLUMES" "(@ @home @var @tmp @.snapshots)"
    else
        NAMES=(@)
        for i in "${ARR[@]}"; do
            if [[ $i =~ [@] ]]; then
                NAMES+=("$i")
            else
                NAMES+=(@"${i}")
            fi
        done
        IFS=" " read -r -a SUBS <<<"$(tr ' ' '\n' <<<"${NAMES[@]}" | awk '!x[$0]++' | tr '\n' ' ')"
        set_option "SUBVOLUMES" "${SUBS[*]}"
    fi
}

set_lvm() {
    read -r -p "Name your lvm volume group [like MyVolGroup, default is MyVolGroup]: " _VG
    if [[ -z "$_VG" ]]; then
        _VG="MyVolGroup"
    fi
    read -r -p "Enter number of partitions [like 2, default is 1]: " _PART_NUM
    echo "Please make sure 1st partition is considered as root partition"
    echo "And will be mounted at /mnt/ and other partitions will be mounted"
    echo "at /mnt/partition_name by making a directory /mnt/partition_name"

    i=1
    _LVM_NAMES=()
    LVM_SIZES=()
    if [[ -z "$_PART_NUM" ]]; then
        _PART_NUM=1
        _LVM_NAMES+=("root")
        # LVM_SIZES+=("100%FREE")
        i=2
    fi
    while [[ $i -le "$_PART_NUM" ]]; do
        if [[ "$_PART_NUM" -eq 1 ]]; then
            read -r -p "Enter last partition name [like home]: " _LVM_NAME
            _LVM_NAMES+=("$_LVM_NAME")
        fi
        read -r -p "Enter $i partition name [like root]: " _LVM_NAME
        _LVM_NAMES+=("$_LVM_NAME")
        read -r -p "Enter $i partition size [like 25G, 200M]: " _LVM_SIZE
        LVM_SIZES+=("$_LVM_SIZE")
        i=$((i + 1))
    done
    IFS=" " read -r -a LVM_NAMES <<<"$(tr ' ' '\n' <<<"${_LVM_NAMES[@]}" | awk '!x[$0]++' | tr '\n' ' ')"
    set_option "LVM_VG" "$_VG"
    set_option "LVM_PART_NUM" "$_PART_NUM"
    set_option "LVM_NAMES" "(${LVM_NAMES[*]})"
    set_option "LVM_SIZES" "(${LVM_SIZES[*]})"
}

elements_present() {
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && break; done
}

invalid_option() {
    echo -ne "ERROR! Your selected option is invalid, retry \n"
}

set_password() {
    read -rs -p "Please enter password: " PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter password: " PASSWORD2
    echo -ne "\n"
    if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
        set_option "$1" "$PASSWORD1"
    else
        echo -ne "ERROR! Passwords do not match \n"
        set_password
    fi
}

title() {
    echo -ne "\n"
    echo -ne "------------------------------------------------------------------------\n"
    echo -ne "\t\t\"$1\"\n"
    echo -ne "------------------------------------------------------------------------\n"
}

# Write shared functions to to setup.conf
write_to_config() {
    cat <<EOF >"$CONFIG_FILE"
#!/usr/bin/env bash

title () {
    echo -ne "\n"
    echo -ne "------------------------------------------------------------------------\n"
    echo -ne "\t\t\$1\n"
    echo -ne "------------------------------------------------------------------------\n"
}

set_option() {
    if grep -Eq "^\${1}.*" "\$CONFIG_FILE"; then
        sed -i -e "/^\${1}.*/d" "\$CONFIG_FILE"
    fi
    echo "\${1}=\${2}" >>"\$CONFIG_FILE"
}

install_pkg () {
    pacman -S --noconfirm --needed "\$@"
}

refresh_pacman() {
    pacman -Sy --noconfirm
}

something_failed() {
    echo "ERROR! Something is not right. Exiting.\n"
    exit 0
}

logo () {
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

# TODO ask user for mount points i.e. boot may be home etc
BOOT=EFIBOOT
ROOT=ROOT
MOUNTPOINT=/mnt
EOF
}

PROMPT="Please enter your option: "

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

background_check() {
    check_root
    check_docker
    check_arch
    check_pacman
    write_to_config
    efi_check
    if connection_test; then
        echo -ne "ERROR! There seems to be no internet connection.\n"
        exit 0
    fi
    set_ntp
    do_curl
}

set_filesystem() {
    title "Setup File System"
    FILESYS=("btrfs" "ext2" "ext3" "ext4" "f2fs" "jfs" "nilfs2" "ntfs" "vfat" "xfs")
    PS3="$PROMPT"
    select OPT in "${FILESYS[@]}"; do
        if elements_present "$OPT" "${FILESYS[@]}"; then
            set_option "FS" "$OPT"
            break
        else
            invalid_option
            set_filesystem
            break
        fi
    done
}

set_partion_layout() {
    title "Setup Partioning Layout"
    LAYOUTS=("LVM" "LVM+LUKS" "Maintain Current")
    PS3="$PROMPT"
    select OPT in "${LAYOUTS[@]}"; do
        if elements_present "$OPT" "${LAYOUTS[@]}"; then
            case "$REPLY" in
            # 1)
            #     set_option "LAYOUT" 1
            #     break
            #     ;;
            1)
                set_option "LVM" 1
                set_lvm
                break
                ;;
            2)
                set_lvm
                set_option "LUKS" 1
                set_option "LUKS_PATH" "/dev/mapper/luks"
                set_password "LUKS_PASSWORD"
                break
                ;;
            3)
                echo -ne "Maintaining current settings"
                CHOICE=($(lsblk | grep 'part' | awk '{print "/dev/" substr($1,3)}'))
                if [[ -d "/sys/firmware/efi/" ]]; then
                    echo "Select your boot partition"
                    PS3="$PROMPT"
                    select OPT in "${CHOICE[@]}"; do
                        if elements_present "$OPT" "${CHOICE[@]}"; then
                            set_option "LAYOUT" 0
                            set_option "BOOT_PARTITION" "$OPT"
                            break
                        fi
                    done
                fi
                echo "Select your root partition"
                PS3="$PROMPT"
                select OPT in "${CHOICE[@]}"; do
                    if elements_present "$OPT" "${CHOICE[@]}"; then
                        set_option "ROOT_PARTITION" "$OPT"
                        break
                    fi
                done
                set_filesystem
                break
                ;;
            *)
                invalid_option
                set_partion_layout
                break
                ;;
            esac
        else
            invalid_option
            set_partion_layout
        fi
    done
}

# Added this from arch wiki https://wiki.archlinux.org/title/System_time
set_timezone() {
    title "Setup Time Zone"
    _TIMEZONE="$(curl --fail https://ipapi.co/timezone)"
    _ZONE=($(timedatectl list-timezones | sed 's/\/.*$//' | uniq))
    echo -ne "System detected your timezone to be '$_TIMEZONE'"
    echo " "
    read -r -p "Is this correct? [like yes/no]: " ANSWER
    case "$ANSWER" in
    y | Y | yes | Yes | YES)
        set_option TIMEZONE "$_TIMEZONE"
        ;;
    n | N | no | NO | No)
        title "Manually setting timezone"
        PS3="$PROMPT"
        echo -ne "Please select your zone: \n"
        select ZONE in "${_ZONE[@]}"; do
            if elements_present "$ZONE" "${_ZONE[@]}"; then
                _SUBZONE=($(timedatectl list-timezones | grep "${ZONE}" | sed 's/^.*\///'))
                PS3="$PROMPT"
                echo -ne "Please select your subzone: \n"
                select SUBZONE in "${_SUBZONE[@]}"; do
                    if elements_present "$SUBZONE" "${_SUBZONE[@]}"; then
                        set_option "TIMEZONE" "${ZONE}/${SUBZONE}"
                        break
                    else
                        invalid_option
                        break
                    fi
                done
                break
            else
                invalid_option
                set_timezone
                break
            fi
        done
        ;;

    *)
        invalid_option
        set_timezone
        ;;
    esac
}

set_keymap() {
    title "Setup Keymap"
    KEYMAPS=("by" "ca" "cf" "cz" "de" "dk" "es" "et" "fa" "fi" "fr" "gr" "hu" "il" "it" "lt" "lv" "mk" "nl" "no" "pl" "ro" "ru" "sg" "ua" "uk" "us")
    PS3="$PROMPT"
    select OPT in "${KEYMAPS[@]}"; do
        if elements_present "$OPT" "${KEYMAPS[@]}"; then
            set_option "KEYMAP" "$OPT"
            break
        else
            invalid_option
            set_keymap
            break
        fi
    done
}

ssd_drive() {
    title "SSD Drive Confirmation"
    read -r -p "Is this system using an SSD? [like yes/no]: " _SSD
    case "$_SSD" in
    y | Y | yes | Yes | YES)
        set_option "SSD" 1
        set_option "MOUNTOPTION" "noatime,compress=zstd,ssd,commit=120"
        ;;
    n | N | no | NO | No)
        set_option "SSD" 0
        set_option "MOUNTOPTION" "noatime,compress=zstd,commit=120"
        ;;
    *)
        invalid_option
        ssd_drive
        ;;
    esac
}

disk_selection() {
    title "Disk Selection"
    DISKLIST="$(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2" - "$3}')" # show disks with /dev/ prefix and size
    PS3="$PROMPT"
    select _DISK in "${DISKLIST[@]}"; do
        if elements_present "$_DISK" "${DISKLIST[@]}"; then
            DISK=$(echo "$_DISK" | awk '{print $1}')
            set_option "DISK" "$DISK"
            break
        else
            invalid_option
            disk_selection
            break
        fi
    done
}

user_info() {
    title "Add Your Information"
    while true; do
        read -r -p "Please enter your username [default is archtitus]: " USERNAME
        if [[ -z "$USERNAME" ]]; then
            set_option "USERNAME" "archtitus"
            break
        elif [[ "${USERNAME,,}" =~ ^[a-z_]([a-z0-9_-]{0,31}|[a-z0-9_-]{0,30}\$)$ ]]; then
            set_option "USERNAME" "${USERNAME,,}" # convert to lower case as in issue #109
            break
        else
            invalid_option
            continue
        fi
    done
    set_password "PASSWORD"
    while true; do
        read -r -p "Please enter your hostname [default is archlinux]: " HOSTNAME
        if [[ -z "$HOSTNAME" ]]; then
            set_option "HOSTNAME" "archlinux"
            break
        elif [[ "${HOSTNAME,,}" =~ ^[a-z][a-z0-9_.-]{0,62}[a-z0-9]$ ]]; then
            set_option "HOSTNAME" "${HOSTNAME,,}"
            break
        else
            invalid_option
            continue
        fi
    done
}

set_locale() {
    title "Setup Locale"
    LOCALES=($(grep UTF-8 /etc/locale.gen | sed 's/\..*$//' | sed '/@/d' | awk '{print $1}' | uniq | sed 's/#//g'))
    PS3="$PROMPT"
    select LOCALE in "${LOCALES[@]}"; do
        if elements_present "$LOCALE" "${LOCALES[@]}"; then
            set_option "LOCALE" "\"${LOCALE}.UTF-8 UTF-8\""
            break
        else
            invalid_option
            set_locale
            break
        fi
    done
}

set_desktop() {
    title "Select either desktop Environment or Window Manager"
    SELECTION=("Default (KDE)" "Gnome" "XFCE" "Mate" "LXQT" "Minimal" "Awesome" "OpenBox" "i3" "i3-Gaps" "Deepin" "Budgie")
    PS3="$PROMPT"
    select OPT in "${SELECTION[@]}"; do
        if elements_present "$OPT" "${SELECTION[@]}"; then
            if [[ "$OPT" == "Default (KDE)" ]]; then
                set_option "DESKTOP" "default"
                break
            else
                set_option "DESKTOP" "${OPT,,}"
                break

            fi
        else
            invalid_option
            set_desktop
            break
        fi
    done

}

set_aur_helper() {
    title "Select your preferred AUR helper"
    SELECTION=("yay" "trizen" "aurman" "aura" "pikaur")
    PS3="$PROMPT"
    select OPT in "${SELECTION[@]}"; do
        if elements_present "$OPT" "${SELECTION[@]}"; then
            set_option "AURHELPER" "$OPT"
            break
        else
            invalid_option
            set_aur_helper
            break
        fi
    done
}

set_bootloader() {
    title "Select your bootloader"
    SELECTION=("Default (GRUB)" "Systemd" "UEFI" "None")
    echo "Systemd and UEFI are only available on a UEFI system"
    echo "None will skip a bootloader and you will not be able to boot"
    PS3="$PROMPT"
    select OPT in "${SELECTION[@]}"; do
        if elements_present "$OPT" "${SELECTION[@]}"; then
            if [[ "$OPT" == "Default (GRUB)" ]]; then
                set_option "BOOTLOADER" "grub"
                break
            else
                set_option "BOOTLOADER" "${OPT,,}"
                break
            fi
        else
            invalid_option
            set_bootloader
            break
        fi
    done
}

make_choice() {
    title "Your system choice"
    CHOICE=("Default Install" "Custom Install")
    PS3="$PROMPT"

    echo "Default installation comprises of the settings and the packages used"
    echo "by Chris Titus himself. More specifically, it uses btrfs as file systems,"
    echo "KDE Plasma as desktop environment and sddm as window manager and package"
    echo "list is in 'pkg-files/pacman-pkgs.txt'."
    echo "While custom install allows you to choose your choices i.e. LVM, LUKS,"
    echo "DE, WM, file systems and etc."
    echo " "
    select OPT in "${CHOICE[@]}"; do
        if elements_present "$OPT" "${CHOICE[@]}"; then
            case "$REPLY" in
            1)
                clear
                logo
                user_info
                disk_selection
                clear
                set_locale
                clear
                set_timezone
                set_keymap
                ssd_drive
                set_btrfs
                set_option "LAYOUT" 1
                set_option "BOOTLOADER" "grub"
                set_option "FS" "btrfs"
                set_option "AURHELPER" "yay"
                set_option "DESKTOP" "default"

                break
                ;;
            2)
                clear
                logo
                user_info
                disk_selection
                clear
                set_locale
                clear
                set_timezone
                set_keymap
                ssd_drive
                # Advance options
                set_aur_helper
                set_partion_layout
                set_bootloader
                set_filesystem
                set_desktop
                break
                ;;
            *)
                invalid_option
                make_choice
                break
                ;;
            esac
        else
            invalid_option
            make_choice
            break
        fi
    done
}
background_check
# write_to_config
clear
logo
make_choice
# user_info
# set_partion_layout
