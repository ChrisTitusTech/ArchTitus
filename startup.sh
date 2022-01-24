#!/usr/bin/env bash
# This script will ask users about their prefrences 
# like disk, file system, timezone, keyboard layout,
# user name, password, etc.

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# set up a config file
CONFIG_FILE=$SCRIPT_DIR/setup.conf
# check if file exists
if [ ! -f "$CONFIG_FILE" ]; then
    # create file if not exists
    touch -f "$CONFIG_FILE"
fi

# set options in setup.conf
set_option() {
    # check if option exists
    if grep -Eq "^${1}.*" "$CONFIG_FILE"; then
        # delete option if exists
        sed -i -e "/^${1}.*/d" "$CONFIG_FILE" 
    fi
    # else add option
    echo "${1}=${2}" >> "$CONFIG_FILE" 
}
# Adding global functions and variables to use in this script

check_root() {
	if [[ "$(id -u)" != "0" ]]; then
		echo -ne "Error: This script has to be run under the 'root' user!"
        exit 1
	fi
}

elements_present() {
    # check if an element exists
	for e in "${@:2}"; do [[ "$e" == "$1" ]] && break; done
}

invalid_option() {
    # invalid option message
    echo -ne "Please select a valid option: \n"
}

set_password() {
    # password helper function
    # read password without echoing (-s)
    read -prs "Please enter password: " PASSWORD1 
    echo -ne "\n"
    read -prs "Please re-enter password: " PASSWORD2
    echo -ne "\n"
    if [ "$PASSWORD1" == "$PASSWORD2" ]; then
       set_option "$1" "$PASSWORD1"
    else
        echo -ne "Passwords do not match \n"
        return
    fi
}

# make a title 
title () {
    echo -ne "\n"
    echo -ne "------------------------------------------------------------------------\n"
    echo -ne "\t\t\t$1\n"
    echo -ne "------------------------------------------------------------------------\n"
}

# ask user for option
PROMPT="Please enter your option: "

logo () {
# This will be shown on every set as user is progressing
echo -ne "
-------------------------------------------------------------------------
 █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
------------------------------------------------------------------------
            Please select presetup settings for your system              
------------------------------------------------------------------------
"
}

filesystem () {
    # This function will handle file systems. At this movement we are handling only
    # btrfs and ext4. Others will be added in future.
    title "File System"
    FILESYS=("btrfs" "ext2" "ext3" "ext4" "f2fs" "jfs" "nilfs2" "ntfs" "reiserfs" "vfat" "xfs")
    PS3="$PROMPT"
    select OPT in "${FILESYS[@]}"; do
        if elements_present "$OPT" "${FILESYS[@]}"; then
            if [ "$OPT" == "btrfs" ]; then
                # used -a to get more than one argument
                echo -ne "Please enter your btrfs subvolume names separated by space\n"
                echo -ne "usualy they are @, @home, @root etc. Defaults are @, @home, @var, @tmp, @.snapshots \n"
                read -pr "or press enter to use defaults: " -a ARR
                if [[  "${ARR[*]}" -eq 0 ]]; then
                    set_option "BTRFS_SUBVOLUME" "(@ @home @var @tmp @.snapshots)"
                    break
                else
                    # An array is a list of values.
                    NAMES=()
                    for i in "${ARR[@]}"; do
                        # push values to array
                        NAMES+=("$i")
                    done
                    # set to config file
                    set_option "BTRFS_SUBVOLUMES" "(${NAMES[*]})"
                    break
                fi
            fi
            set_option "FS" "$OPT"
            break
        else
            invalid_option
            break
        fi
    done
}

timezone () {
    # Added this from arch wiki https://wiki.archlinux.org/title/System_time
    _TIMEZONE="$(curl --fail https://ipapi.co/timezone)"
    _ZONE=($(timedatectl list-timezones | sed 's/\/.*$//' | uniq))
    echo -ne "System detected your timezone to be '$_TIMEZONE'"
    echo -ne  "\n"
    read -pr "Is this correct? yes/no: " ANSWER
    case "$ANSWER" in
        y|Y|yes|Yes|YES)
            set_option TIMEZONE "$_TIMEZONE"
            ;;
        n|N|no|NO|No)
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
                            set_option TIMEZONE "${ZONE}/${SUBZONE}"
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

        *) echo "Wrong option. Try again";timezone;;
    esac
}

keymap () {
    # These are default key maps as presented in official arch repo archinstall
    KEYMAPS=("by" "ca" "cf" "cz" "de" "dk" "es" "et" "fa" "fi" "fr" "gr" "hu" "il" "it" "lt" "lv" "mk" "nl" "no" "pl" "ro" "ru" "sg" "ua" "uk" "us")
    PS3="$PROMPT"
    select OPT in "${KEYMAPS[@]}"; do
        if elements_present "$OPT" "${KEYMAPS[@]}"; then
            set_option KEYMAP "$OPT"
            break
        else
            invalid_option
            keymap
        fi
    done
}

drivessd () {
    # confirm if ssd is present
    read -pr "Is this system using an SSD? yes/no: " _SSD
    case "$_SSD" in
        y|Y|yes|Yes|YES)
            set_option "SSD" 1
            set_option "MOUNTOPTION" "noatime,compress=zstd,ssd,commit=120"
            ;;
        n|N|no|NO|No)
            set_option "SSD" 0
            set_option "MOUNTOPTION" "noatime,compress=zstd,commit=120"
            ;;
        *) echo "Wrong option. Try again";drivessd;;
    esac
}

# selection for disk type
diskpart () {
# show disks present on system
lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print NR,"/dev/"$2" - "$3}' # show disks with /dev/ prefix and size
echo -ne "
------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK             
    Please make sure you know what you are doing because         
    after formating your disk there is no way to get data back      
------------------------------------------------------------------------

Please enter full path to disk: (example /dev/sda):
"
read -r option
echo "DISK=$option" >> setup.conf

drivessd
set_option DISK "$option"
}

userinfo () {
    read -pr "Please enter your username: " USERNAME
    set_option USERNAME "${USERNAME,,}" # convert to lower case as in issue #109 
    set_password "PASSWORD"
    read -pr "Please enter your hostname: " HOSTNAME
    set_option HOSTNAME "$HOSTNAME"
}
# More features in future
# language (){}

# Starting functions
clear
logo
userinfo
clear
logo
diskpart
clear
logo
filesystem
clear
logo
timezone
clear
logo
keymap