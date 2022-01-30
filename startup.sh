#!/usr/bin/env bash
# This script will ask users about their prefrences
# like disk, file system, timezone, keyboard layout,
# user name, password, etc.
# shellcheck disable=SC2207,SC2120

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Set up a config file
CONFIG_FILE="$SCRIPT_DIR"/setup.conf 

# Check if file exists and remove it if it does
[[ -f "$CONFIG_FILE" ]] && rm -f "$CONFIG_FILE" > /dev/null 2>&1

# Set options in setup.conf
set_option() {
    # Check if option exists
    if grep -Eq "^${1}.*" "$CONFIG_FILE"; then
        # delete option if exists
        sed -i -e "/^${1}.*/d" "$CONFIG_FILE"
    fi
    # Else add option
    echo "${1}=${2}" >>"$CONFIG_FILE"
}

# Adding global functions and variables to use in this script

# Check for root user
check_root() {
    if [[ "$(id -u)" != "0" ]]; then
        echo -ne "ERROR! This script has to be run under the 'root' user!"
        exit 1
    fi
}

# Check if distro is arch
check_arch() {
    if [[ ! -e /etc/arch-release ]]; then
        echo -ne "ERROR! This script has to be run under Arch Linux!"
        exit 1
    fi
}

# Check for internet connection
connection_test() {
    ping -q -w 1 -c 1 "$(ip r | grep default | awk 'NR==1 {print $3}')" &>/dev/null && return 1 || return 0
}

# Check coutry for mirrorlist
do_curl() {
    _ISO=$(curl --fail https://ifconfig.co/country-iso)
    set_option "ISO" "$_ISO"
}

# Install fonts
install_font() {
    pacman -S --noconfirm --needed terminus-font
}

# timedatectl set-ntp true
set_ntp() {
    timedatectl set-ntp true
}

# Check for UEFI
efi_check() {
    if [[ -d "/sys/firmware/efi/" ]]; then
        if (mount | grep /sys/firmware/efi/efivars); then
            (mount -t efivarfs efivarfs /sys/firmware/efi/efivars) > /dev/null 2>&1
        fi
        # UEFI detected
        set_option "UEFI" 1
    else
        # No UEFI detected
        set_option "UEFI" 0
    fi
}

# if btrfs is selected
set_btrfs() {
    # Used -a to get more than one argument
    echo "Please enter your btrfs subvolumes separated by space"
    echo "usualy they start with @."
    echo "[like @home, default are @home, @var, @tmp, @.snapshots]"
    echo " "
    read -r -p "press enter to use default: " -a ARR
    if [[ -z "${ARR[*]}" ]]; then
        set_option "SUBVOLUMES" "(@ @home @var @tmp @.snapshots)"
    else
        # An array is a list of values.
        NAMES=(@)
        for i in "${ARR[@]}"; do
            # Check for user input for @
            if [[ $i =~ [@] ]]; then
                # push values to array
                NAMES+=("$i")
            else
                NAMES+=(@"${i}")
            fi
        done
        # Check for duplicates
        IFS=" " read -r -a SUBS <<<"$(tr ' ' '\n' <<<"${NAMES[@]}" | sort -u | tr '\n' ' ')"
        # Set to config file
        set_option "SUBVOLUMES" "${SUBS[*]}"
    fi
}

# If lvm is selected
set_lvm() {
    read -r -p "Name your lvm volume group [like MyVolGroup, default is MyVolGroup]: " _VG
    if [[ -z "$_VG" ]]; then
        _VG="MyVolGroup"
    fi
    read -r -p "Enter number of partitions [like 2, default is 1]: " _PART_NUM
    echo "Please make sure 1st partition is considered as root partition"
    echo "And will be mounted at /mnt/ and other partitions will be mounted"
    echo "at /mnt/partition_name by making a directory /mnt/partition_name"
    if [[ -z "$PART_NUM" ]]; then
        PART_NUM=1
    fi
    i=1
    _LVM_NAMES=()
    _LVM_SIZES=()
    while [[ $i -le "$_PART_NUM" ]]; do
        read -r -p "Enter $i partition name [like root, default is root]: " _LVM_NAME
        if [[ -z "$_LVM_NAME" ]]; then
            _LVM_NAME="root"
        fi
        _LVM_NAMES+=("$_LVM_NAME")
        read -r -p "Enter $i partition size [like 25G, 200M]: " _LVM_SIZE
        _LVM_SIZES+=("$_LVM_SIZE")
        i=$((i + 1))
    done
    IFS=" " read -r -a LVM_NAMES <<<"$(tr ' ' '\n' <<<"${_LVM_NAMES[@]}" | sort -u | tr '\n' ' ')"
    IFS=" " read -r -a LVM_SIZES <<<"$(tr ' ' '\n' <<<"${_LVM_SIZES[@]}" | sort -u | tr '\n' ' ')"
    set_option "LVM_VG" "$_VG"
    set_option "LVM_PART_NUM" "$_PART_NUM"
    set_option "LVM_NAMES" "${LVM_NAMES[*]}"
    set_option "LVM_SIZES" "${LVM_SIZES[*]}"
}

# Check if an element exists
elements_present() {
    for e in "${@:2}"; do [[ "$e" == "$1" ]] && break; done
}

# Invalid option message
invalid_option() {
    echo -ne "Please select a valid option: \n"
}

# Password helper function
set_password() {
    # Read password without echoing (-s)
    read -rs -p "Please enter password: " PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter password: " PASSWORD2
    echo -ne "\n"
    if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
        set_option "$1" "$PASSWORD1"
    else
        echo -ne "Passwords do not match \n"
        set_password
    fi
}

# Make a title
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

install_pkg () {
    pacman -S --noconfirm --needed "\$@"
}

refresh_pacman() {
    pacman -Syy
}

# Setup for logging
LOG="${SCRIPT_DIR}/main.log"
[[ -f \$LOG ]] && rm -f "\$LOG"

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
EOF
}

# Ask user for option
PROMPT="Please enter your option: "

# This will be shown on every set as user is progressing
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

# Backround checks
background_check() {
    write_to_config
    if connection_test; then
        echo -ne "ERROR! There seems to be no internet connection.\n"
        exit 1
    fi
    set_option "SCRIPT_DIR" "$SCRIPT_DIR"
    check_arch
    efi_check
    # check_root
    set_ntp
    do_curl
    install_font
    setfont ter-v22b
}

# Set partioning layouts
set_partion_layout() {
    title "Setup Partioning Layout"
    LAYOUTS=("Default" "LVM" "LVM+LUKS" "Maintain Current")
    PS3="$PROMPT"
    select OPT in "${LAYOUTS[@]}"; do
        if elements_present "$OPT" "${LAYOUTS[@]}"; then
            case "$REPLY" in
            1)
                set_option "LAYOUT" 1
                break
                ;;
            2)
                set_lvm
                set_option "LVM" 1
                set_option "LUKS" 0
                break
                ;;
            3)
                set_lvm
                set_option "LUKS" 1
                set_option "LVM" 1
                set_option "LUKS_PATH" "/dev/mapper/ROOT"
                set_password "LUKS_PASSWORD"
                break
                ;;
            4)
                echo -ne "Maintaining current settings"
                CHOICE=($(lsblk | grep 'part' | awk '{print "/dev/" substr($1,3)}'))
                PS3="$PROMPT"
                select OPT in "${CHOICE[@]}"; do
                    if elements_present "$OPT" "${CHOICE[@]}"; then
                        set_option "LAYOUT" 0
                        set_option "PARTITION" "$OPT"
                        break
                    fi
                done
                break
                ;;
            *)
                invalid_option
                set_partion_layout
                ;;
            esac
        else
            invalid_option
            set_partion_layout
        fi
    done
}

# This function will handle file systems.
set_filesystem() {
    title "Setup File System"
    FILESYS=("btrfs" "ext2" "ext3" "ext4" "f2fs" "jfs" "nilfs2" "ntfs" "reiserfs" "vfat" "xfs")
    PS3="$PROMPT"
    select OPT in "${FILESYS[@]}"; do
        if elements_present "$OPT" "${FILESYS[@]}"; then
            set_option "FS" "$OPT"
            break
        else
            invalid_option
            break
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
    read -r -p "Is this correct? [like yes/no, default is yes]: " ANSWER
    if [[ -z "$ANSWER" ]]; then
        ANSWER="yes"
    fi
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
                break
            fi
        done
        ;;

    *)
        echo "Wrong option. Try again"
        set_timezone
        ;;
    esac
}

# These are default key maps as presented in official arch repo archinstall
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
            break
        fi
    done
}

# Confirm if ssd is present
ssd_drive() {
    title "SSD Drive Confirmation"
    read -r -p "Is this system using an SSD? [like yes/no, default is no]: " _SSD
    if [[ -z "$_SSD" ]]; then
        _SSD="no"
    fi
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
        echo "Wrong option. Try again"
        ssd_drive
        ;;
    esac
}

# Selection for disk type
disk_selection() {
    # show disks present on system
    title "Disk Selection"
    DISKLIST="$(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2" - "$3}')" # show disks with /dev/ prefix and size
    PS3="$PROMPT"
    select _DISK in "${DISKLIST[@]}"; do
        if elements_present "$_DISK" "${DISKLIST[@]}"; then
            # remove size from string
            DISK=$(echo "$_DISK" | awk '{print $1}')
            set_option "DISK" "$DISK"
            break
        else
            invalid_option
            break
        fi
    done
}

user_info() {
    title "Add Your Information"
    read -r -p "Please enter your username [default is archtitus]: " USERNAME
    if [[ -z "$USERNAME" ]]; then
        USERNAME="archtitus"
    fi
    set_option "USERNAME" "${USERNAME,,}" # convert to lower case as in issue #109
    set_password "PASSWORD"
    read -r -p "Please enter your hostname [default is ArchLinux]: " HOSTNAME
    if [[ -z "$HOSTNAME" ]]; then
        HOSTNAME="ArchLinux"
    fi
    set_option "HOSTNAME" "$HOSTNAME"
}

# Set locale
set_locale() {
    title "Setup Locale"
    LOCALES=($(grep UTF-8 /etc/locale.gen | sed 's/\..*$//' | sed '/@/d' | awk '{print $1}' | uniq | sed 's/#//g'))
    PS3="$PROMPT"
    select LOCALE in "${LOCALES[@]}"; do
        if elements_present "$LOCALE" "${LOCALES[@]}"; then
            set_option "LOCALE" "${LOCALE}.UTF-8 UTF-8"
            break
        else
            invalid_option
            break
        fi
    done
}

# Desktop selection
set_desktop() {
    title "Select either desktop Environment or Window Manager"
    SELECTION=("KDE" "Gnome" "XFCE" "Mate" "LXQT" "Minimal" "Awesome" "OpenBox" "i3" "i3-Gaps")
    PS3="$PROMPT"
    select OPT in "${SELECTION[@]}"; do
        if elements_present "$OPT" "${SELECTION[@]}"; then
            case "$REPLY" in
            1)
                # More packages can be added here
                set_option "DE" "plasma"
                set_option "DM" "sddm"
                break
                ;;
            2)
                set_option "DE" "gnome"
                set_option "DM" "gdm"
                break
                ;;
            3)
                set_option "DE" "xfce4"
                set_option "DM" "lightdm"
                break
                ;;
            4)
                set_option "DE" "mate"
                set_option "DM" "lightdm"
                break
                ;;
            5)
                set_option "DE" "lxqt"
                set_option "DM" "lightdm"
                break
                ;;
            6)
                set_option "DE" 0
                set_option "DM" 0
                break
                ;;
            7)
                set_option "DE" 0
                set_option "WM" "awesome"
                break
                ;;
            8) # openbox
                set_option "DE" 0
                set_option "WM" "openbox"
                break
                ;;
            9) # i3
                set_option "DE" 0
                set_option "WM" "i3"
                break
                ;;
            10) # i3-gaps
                set_option "DE" 0
                set_option "WM" "i3-gaps"
                break
                ;;
            *)
                echo "Wrong option. Try again"
                break
                ;;
            esac
        else
            invalid_option
            break
        fi
    done

}

# Make choice for installation
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
                # title "Please select presetup \n\t\t\tsettings for your system"
                user_info
                disk_selection
                clear
                set_locale
                clear
                set_timezone
                set_keymap
                ssd_drive
                set_btrfs
                set_option "FS" "btrfs"
                set_option "DE" "plasma"
                set_option "DM" "sddm"
                set_option "LAYOUT" 1

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
                set_partion_layout
                set_filesystem
                set_desktop
                break
                ;;
            *)
                echo "Wrong option. Try again"
                break
                ;;
            esac
        else
            invalid_option
            break
        fi
    done
}
background_check
# # write_to_config
# clear
# logo
# make_choice
