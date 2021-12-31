#!/usr/bin/env bash
# This script will ask users about their prefrences like disk, file system,
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
1) echo "FS=btrfs" >> setup.conf;;
2) echo "FS=ext4" >> setup.conf;;
3) 
echo -ne "Please enter your luks password: "
read luks_password
echo "luks_password=$luks_password" >> setup.conf
echo "FS=luks" >> setup.conf;;
0) exit ;;
*) echo "Wrong option please select again"; filesystem;;
esac
}
timezone () {
# Added this from arch wiki https://wiki.archlinux.org/title/System_time
time_zone="$(curl --fail https://ipapi.co/timezone)"
echo -ne "System detected your timezone to be '$time_zone'"
echo -ne "Is this correct? yes/no:" 
read answer
case $answer in
    y|Y|yes|Yes|YES)
    echo "timezone=$time_zone" >> setup.conf;;
    n|N|no|NO|No)
    echo "Please enter your desired timezone e.g. Europe/London :" 
    read new_timezone
    echo "timezone=$new_timezone" >> setup.conf;;
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
read -p "Your key boards layout:" keymap
echo "keymap=$keymap" >> setup.conf
}
diskpart () {
lsblk
echo -ne "
------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK             
    Please make sure you know what you are doing because         
    after formating your disk there is no way to get data back      
------------------------------------------------------------------------

Please enter disk to work on: (example /dev/sda):
"
read option
echo "DISK=$option" >> setup.conf
}
userinfo () {
echo -ne "Please enter username: "
read username
echo "username=$username" >> setup.conf
echo -ne "Please enter your password: "
read password
echo "password=$password" >> setup.conf
echo -ne "Please enter your hostname: "
read hostname
echo "hostname=$hostname" >> setup.conf
}
# More features in future
# language (){}
rm -rf setup.conf &>/dev/null
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