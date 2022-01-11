#!/usr/bin/env bash
# This script will ask users about their prefrences 
# like disk, file system, timezone, keyboard layout,
# user name, password, etc.

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# set up a config file
CONFIG_FILE=$SCRIPT_DIR/setup.conf
if [ ! -f $CONFIG_FILE ]; then # check if file exists
    touch -f $CONFIG_FILE # create file if not exists
fi

# set options in setup.conf
set_option() {
    if grep -Eq "^${1}.*" $CONFIG_FILE; then # check if option exists
        sed -i -e "/^${1}.*/d" $CONFIG_FILE # delete option if exists
    fi
    echo "${1}=${2}" >>$CONFIG_FILE # add option
}
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
echo -ne "
    Please Select your file system for both boot and root
    1)      btrfs
    2)      ext4
    3)      luks with btrfs
    0)      exit
"
read FS
case $FS in
1) set_option FS btrfs;;
2) set_option FS ext4;;
3) 
echo -ne "Please enter your luks password: "
read -s LUKS_PASSWORD # read password without echo
set_option LUKS_PASSWORD $LUKS_PASSWORD
set_option FS luks;;
0) exit ;;
*) echo "Wrong option please select again"; filesystem;;
esac
}
timezone () {
# Added this from arch wiki https://wiki.archlinux.org/title/System_time
TIME_ZONE="$(curl --fail https://ipapi.co/timezone)"
echo -ne "System detected your timezone to be '$TIME_ZONE' \n"
echo -ne "Is this correct? yes/no:" 
read answer
case $answer in
    y|Y|yes|Yes|YES)
    set_option TIMEZONE $TIME_ZONE;;
    n|N|no|NO|No)
    echo "Please enter your desired timezone e.g. Europe/London :" 
    read NEW_TIMEZONE
    set_option TIMEZONE $NEW_TIMEZONE;;
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
read -p "Your key boards layout:" KEYMAP
set_option KEYMAP $KEYMAP
}

drivessd () {
echo -ne "
Is this an ssd? yes/no:
"
read SSD_DRIVE

case $SSD_DRIVE in
    y|Y|yes|Yes|YES)
    echo "MOUNT_OPTIONS=noatime,compress=zstd,ssd,commit=120" >> setup.conf;;
    n|N|no|NO|No)
    echo "MOUNT_OPTIONS=noatime,compress=zstd,commit=120" >> setup.conf;;
    *) echo "Wrong option. Try again";drivessd;;
esac
}

# selection for disk type
diskpart () {
# show disks present on system
lsblk -n --output TYPE,KNAME | awk '$1=="disk"{print NR,"/dev/"$2}' # show disks with /dev/ prefix
echo -ne "
------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK             
    Please make sure you know what you are doing because         
    after formating your disk there is no way to get data back      
------------------------------------------------------------------------

Please enter full path to disk: (example /dev/sda):
"
read OPTION
echo "DISK=$OPTION" >> setup.conf

drivessd
set_option DISK $OPTION
}
userinfo () {
read -p "Please enter your username: " USERNAME
set_option USERNAME ${USERNAME,,} # convert to lower case as in issue #109 
echo -ne "Please enter your password: \n"
read -s PASSWORD # read password without echo
set_option PASSWORD $PASSWORD
read -rep "Please enter your hostname: " NAME_OF_MACHINE
set_option NAME_OF_MACHINE $NAME_OF_MACHINE
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