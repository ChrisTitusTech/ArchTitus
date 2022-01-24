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
time_zone="$(curl --fail https://ipapi.co/timezone)"
echo -ne "System detected your timezone to be '$time_zone' \n"
echo -ne "Is this correct? yes/no:" 
read -r answer
case $answer in
    y|Y|yes|Yes|YES)
    set_option TIMEZONE "$time_zone";;
    n|N|no|NO|No)
    echo "Please enter your desired timezone e.g. Europe/London :" 
    read -r new_timezone
    set_option TIMEZONE "$new_timezone";;
    *) echo "Wrong option. Try again";timezone;;
esac
}
keymap () {
# These are default key maps as presented in official arch repo archinstall
echo -ne "
Please select key board layout from this list
    -by
    -ca
    -cf
    -cz
    -de
    -dk
    -es
    -et
    -fa
    -fi
    -fr
    -gr
    -hu
    -il
    -it
    -lt
    -lv
    -mk
    -nl
    -no
    -pl
    -ro
    -ru
    -sg
    -ua
    -uk
    -us

"
read -rp "Your key boards layout:" keymap
set_option KEYMAP $keymap
}

drivessd () {
echo -ne "
Is this an ssd? yes/no:
"
read -r ssd_drive

case $ssd_drive in
    y|Y|yes|Yes|YES)
    echo "mountoptions=noatime,compress=zstd,ssd,commit=120" >> setup.conf;;
    n|N|no|NO|No)
    echo "mountoptions=noatime,compress=zstd,commit=120" >> setup.conf;;
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
read -rp "Please enter your username: " username
set_option USERNAME "${username,,} "# convert to lower case as in issue #109 
echo -ne "Please enter your password: \n"
read -rs password # read password without echo
set_option PASSWORD "$password"
read -rp "Please enter your hostname: " nameofmachine
set_option nameofmachine "$nameofmachine"
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