#!/usr/bin/env bash
#github-action genshdoc
#
# @file Startup
# @brief This script will ask users about their prefrences like disk, file system, timezone, keyboard layout, user name, password, etc.
# @stdout Output routed to startup.log
# @stderror Output routed to startup.log

# @setting-header General Settings
# @setting CONFIG_FILE string[$CONFIGS_DIR/setup.conf] Location of setup.conf to be used by set_option and all subsequent scripts. 
CONFIG_FILE=$CONFIGS_DIR/setup.conf
if [ ! -f $CONFIG_FILE ]; then # check if file exists
    touch -f $CONFIG_FILE # create file if not exists
fi

# @description set options in setup.conf
# @arg $1 string Configuration variable.
# @arg $2 string Configuration value.
set_option() {
    if grep -Eq "^${1}.*" $CONFIG_FILE; then # check if option exists
        sed -i -e "/^${1}.*/d" $CONFIG_FILE # delete option if exists
    fi
    echo "${1}=${2}" >>$CONFIG_FILE # add option
}

set_password() {
    read -rs -p "Please enter password: " PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter password: " PASSWORD2
    echo -ne "\n"
    if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
        set_option "$1" "$PASSWORD1"
    else
        echo -ne "ERROR! Passwords do not match. \n"
        set_password
    fi
}

root_check() {
    if [[ "$(id -u)" != "0" ]]; then
        echo -ne "ERROR! This script must be run under the 'root' user!\n"
        exit 0
    fi
}

docker_check() {
    if awk -F/ '$2 == "docker"' /proc/self/cgroup | read -r; then
        echo -ne "ERROR! Docker container is not supported (at the moment)\n"
        exit 0
    elif [[ -f /.dockerenv ]]; then
        echo -ne "ERROR! Docker container is not supported (at the moment)\n"
        exit 0
    fi
}

arch_check() {
    if [[ ! -e /etc/arch-release ]]; then
        echo -ne "ERROR! This script must be run in Arch Linux!\n"
        exit 0
    fi
}

pacman_check() {
    if [[ -f /var/lib/pacman/db.lck ]]; then
        echo "ERROR! Pacman is blocked."
        echo -ne "If not running remove /var/lib/pacman/db.lck.\n"
        exit 0
    fi
}

background_checks() {
    root_check
    arch_check
    pacman_check
    docker_check
}

# Renders a text based list of options that can be selected by the
# user using up, down and enter keys and returns the chosen option.
#
#   Arguments   : list of options, maximum of 256
#                 "opt1" "opt2" ...
#   Return value: selected index (0 for opt1, 1 for opt2 ...)
select_option() {

    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "$2   $1 "; }
    print_selected()   { printf "$2  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    get_cursor_col()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${COL#*[}; }
    key_input()         {
                        local key
                        IFS= read -rsn1 key 2>/dev/null >&2
                        if [[ $key = ""      ]]; then echo enter; fi;
                        if [[ $key = $'\x20' ]]; then echo space; fi;
                        if [[ $key = "k" ]]; then echo up; fi;
                        if [[ $key = "j" ]]; then echo down; fi;
                        if [[ $key = "h" ]]; then echo left; fi;
                        if [[ $key = "l" ]]; then echo right; fi;
                        if [[ $key = "a" ]]; then echo all; fi;
                        if [[ $key = "n" ]]; then echo none; fi;
                        if [[ $key = $'\x1b' ]]; then
                            read -rsn2 key
                            if [[ $key = [A || $key = k ]]; then echo up;    fi;
                            if [[ $key = [B || $key = j ]]; then echo down;  fi;
                            if [[ $key = [C || $key = l ]]; then echo right;  fi;
                            if [[ $key = [D || $key = h ]]; then echo left;  fi;
                        fi 
    }
    print_options_multicol() {
        # print options by overwriting the last lines
        local curr_col=$1
        local curr_row=$2
        local curr_idx=0

        local idx=0
        local row=0
        local col=0
        
        curr_idx=$(( $curr_col + $curr_row * $colmax ))
        
        for option in "${options[@]}"; do

            row=$(( $idx/$colmax ))
            col=$(( $idx - $row * $colmax ))

            cursor_to $(( $startrow + $row + 1)) $(( $offset * $col + 1))
            if [ $idx -eq $curr_idx ]; then
                print_selected "$option"
            else
                print_option "$option"
            fi
            ((idx++))
        done
    }

    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done

    # determine current screen position for overwriting the options
    local return_value=$1
    local lastrow=`get_cursor_row`
    local lastcol=`get_cursor_col`
    local startrow=$(($lastrow - $#))
    local startcol=1
    local lines=$( tput lines )
    local cols=$( tput cols ) 
    local colmax=$2
    local offset=$(( $cols / $colmax ))

    local size=$4
    shift 4

    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    local active_row=0
    local active_col=0
    while true; do
        print_options_multicol $active_col $active_row 
        # user key control
        case `key_input` in
            enter)  break;;
            up)     ((active_row--));
                    if [ $active_row -lt 0 ]; then active_row=0; fi;;
            down)   ((active_row++));
                    if [ $active_row -ge $(( ${#options[@]} / $colmax ))  ]; then active_row=$(( ${#options[@]} / $colmax )); fi;;
            left)     ((active_col=$active_col - 1));
                    if [ $active_col -lt 0 ]; then active_col=0; fi;;
            right)     ((active_col=$active_col + 1));
                    if [ $active_col -ge $colmax ]; then active_col=$(( $colmax - 1 )) ; fi;;
        esac
    done

    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on

    return $(( $active_col + $active_row * $colmax ))
}
# @description Displays ArchTitus logo
# @noargs
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
# @description This function will handle file systems. At this movement we are handling only
# btrfs and ext4. Others will be added in future.
filesystem () {
echo -ne "
Please Select your file system for both boot and root
"
options=("btrfs" "ext4" "luks" "exit")
select_option $? 1 "${options[@]}"

case $? in
0) set_option FS btrfs;;
1) set_option FS ext4;;
2) 
    set_password "LUKS_PASSWORD"
    set_option FS luks
    ;;
3) exit ;;
*) echo "Wrong option please select again"; filesystem;;
esac
}
# @description Detects and sets timezone. 
timezone () {
# Added this from arch wiki https://wiki.archlinux.org/title/System_time
time_zone="$(curl --fail https://ipapi.co/timezone)"
echo -ne "
System detected your timezone to be '$time_zone' \n"
echo -ne "Is this correct?
" 
options=("Yes" "No")
select_option $? 1 "${options[@]}"

case ${options[$?]} in
    y|Y|yes|Yes|YES)
    echo "${time_zone} set as timezone"
    set_option TIMEZONE $time_zone;;
    n|N|no|NO|No)
    echo "Please enter your desired timezone e.g. Europe/London :" 
    read new_timezone
    echo "${new_timezone} set as timezone"
    set_option TIMEZONE $new_timezone;;
    *) echo "Wrong option. Try again";timezone;;
esac
}
# @description Set user's keyboard mapping. 
keymap () {
echo -ne "
Please select key board layout from this list"
# These are default key maps as presented in official arch repo archinstall
options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru sg ua uk)

select_option $? 4 "${options[@]}"
keymap=${options[$?]}

echo -ne "Your key boards layout: ${keymap} \n"
set_option KEYMAP $keymap
}

# @description Choose whether drive is SSD or not.
drivessd () {
echo -ne "
Is this an ssd? yes/no:
"

options=("Yes" "No")
select_option $? 1 "${options[@]}"

case ${options[$?]} in
    y|Y|yes|Yes|YES)
    set_option MOUNT_OPTIONS "noatime,compress=zstd,ssd,commit=120";;
    n|N|no|NO|No)
    set_option MOUNT_OPTIONS "noatime,compress=zstd,commit=120";;
    *) echo "Wrong option. Try again";drivessd;;
esac
}

# @description Select a Disk to open in cfdisk to create or modify partitions manually.
manualpart () {
  clear
  echo -ne "
------------------------------------------------------------------------
    WARNING: CFDISK IS A COMMAND LINE DISK PARTITION MANAGEMENT TOOL.
    IT MAY BE HAZARDOUS TO USE IT IF YOU ARE NOT FAMILIER WITH IT.
    This might cost you all your data stored in this device.
------------------------------------------------------------------------

"

  lsblk

  echo -e "\nSelect the disk which you want to partition: "
  options=($(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}'))

  select_option $? 1 "${options[@]}"
  cfdisk ${options[$?]%|*}
}

# @description Disk drive or partition selection to which Arch will be installed.
diskpart () {
clear
echo -ne "
------------------------------------------------------------------------
    WARNING: THIS MAY FORMAT AND DELETE ALL DATA ON THE DISK.
    Please make sure you know what you are doing because
    after formating your disk there is no way to get data back.
------------------------------------------------------------------------

"

fdisk -l

options=("Install in a specific Disk Partition" "Install in a whole Disk Drive" "Modify partitions using cfdisk")
select_option $? 1 "${options[@]}"

case $? in

0)
  clear
  echo -ne "
------------------------------------------------------------------------
    WARNING: ARCH LINUX WILL BE INSTALLED IN THE SELECTED PARTITION.
    This will delete all the data present in it, so make sure that
    you select the right partition that donot contain any useful files.
------------------------------------------------------------------------

"

  fdisk -l

  echo -e "\nWhich disk do you want to select the partition from?"
  options=($(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}'))

  select_option $? 1 "${options[@]}"
  disk=${options[$?]%|*}
  set_option DISK ${disk%|*}

  echo -e "\n"
  echo "Select the Partition to Install on (This will be the root partition mounted on \"\\\"): "
  options=($(lsblk -n --output TYPE,KNAME,SIZE,MOUNTPOINT ${disk%|*} | awk '$1=="part"{print "/dev/"$2"|"$3"__________"$4}'))
  
  select_option $? 1 "${options[@]}"
  part=${options[$?]%|*}
  set_option INSTALL_IN "PART"
  set_option PART ${part%|*}

  echo -e "\n${part%|*} selected as root partition. Is that OK?"
  options=("Yes" "No")
  select_option $? 1 "${options[@]}"

  case ${options[$?]} in
  y|Y|yes|Yes|YES)
    drivessd ;;
  n|N|no|NO|No)
    diskpart
    return
  ;;
  *)
    diskpart
    return
  ;;
  esac

  if [[ -d "/sys/firmware/efi" ]]; then # Checking for UEFI System
    clear
    echo -en "
    ------------------------------------------------------------------------
        NOTE: If you had installed Windows or any other OS in the current
        disk drive, an EFI System partition may already exist in it.
        Identify it from the table below and select it. But, if it doesnot
        exist, then create a partition of size 100 MB and set its type to
        EFI System and choose \"yes\" when asked if you want to format it.
    ------------------------------------------------------------------------

    "

    fdisk -l

    echo -e "\n"
    echo "Select the EFI Partition (This partition should be in FAT32 format and about 100-500 MB in size. It will be mounted on \"\\Boot\\EFI\"): "
    options=("Create" $(lsblk -n --output TYPE,KNAME,SIZE,MOUNTPOINT | awk '$1=="part"{print "/dev/"$2"|"$3"__________"$4}'))
  
    select_option $? 1 "${options[@]}"
    case $? in
    0)
      manualpart
      diskpart
      return
    ;;
    *)
      BOOTpart=${options[$?]%|*}
      set_option BOOTPART ${BOOTpart%|*}
    ;;
    esac

    echo -e "\n${BOOTpart%|*} selected as EFI partition. Is that OK?"
    options=("Yes" "No")
    select_option $? 1 "${options[@]}"
    case ${options[$?]} in
    y|Y|yes|Yes|YES)
      return ;;
    n|N|no|NO|No)
      diskpart
      return
    ;;
    *)
      diskpart
      return
    ;;
    esac

    echo -e "\nDo you want to format the selected EFI partition?"
    options=("Yes" "No")
    select_option $? 1 "${options[@]}"
    case ${options[$?]} in
    y|Y|yes|Yes|YES) set_option FORMATEFI "yes" ;;
    n|N|no|NO|No) set_option FORMATEFI "no" ;;
    *) set_option FORMATEFI "no" ;;
    esac

  elif [[ $(fdisk -l ${disk%|*} | grep -i 'Disklabel type') = "Disklabel type: gpt" ]]; then # Checking for GPT Disk Label on a Legacy BIOS (non UEFI) System
    clear
    echo -en "
    ------------------------------------------------------------------------
        GUID Partition Table (GPT) detected on a Legacy BIOS System.
        If you had installed Windows or any other OS in the current
        disk drive, a BIOS BOOT partition may already exist in it.
        Identify it from the table below and select it. But, if it
        doesnot exist, then create a partition of size 100 MB and set
        its type to BIOS BOOT.
    ------------------------------------------------------------------------

    "

    fdisk -l

    echo -e "\n"
    echo "Select the BIOS BOOT Partition (This partition should be about 100-500 MB in size and should have BIOS boot label.): "
    options=("Create a BIOS BOOT partition using cfdisk" $(lsblk -n --output TYPE,KNAME,SIZE,MOUNTPOINT | awk '$1=="part"{print "/dev/"$2"|"$3"__________"$4}'))
    select_option $? 1 "${options[@]}"
    case $? in
    0)
      manualpart
      diskpart
      return
    ;;
    *)
      BOOTpart=${options[$?]%|*}
      set_option BOOTPART ${BOOTpart%|*}
      set_option FORMATEFI "no"
    ;;
    esac

    echo -e "\n${BOOTpart%|*} selected as BIOS BOOT partition. Is that OK?"
    options=("Yes" "No")
    select_option $? 1 "${options[@]}"

    case ${options[$?]} in
    y|Y|yes|Yes|YES)
      return ;;
    n|N|no|NO|No)
      diskpart
      return
    ;;
    *)
      diskpart
      return
    ;;
    esac
  fi
;;

1)
  clear
  echo -ne "
------------------------------------------------------------------------
    WARNING: ARCH LINUX WILL BE INSTALLED IN THE SELECTED DISK DRIVE.
    This will delete all the data present in it, so make sure that
    you select the right disk drive that donot contain any useful files.
------------------------------------------------------------------------

"

  lsblk

  echo -e "\nSelect the disk to install on: "
  options=($(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}'))

  select_option $? 1 "${options[@]}"
  disk=${options[$?]%|*}
  set_option INSTALL_IN "DISK"
  set_option DISK ${disk%|*}
  set_option PART ""
  set_option BOOTPART ""
  set_option FORMATEFI "no"

  echo -e "\n${disk%|*} selected. Is that OK?"
  options=("Yes" "No")
  select_option $? 1 "${options[@]}"

  case ${options[$?]} in
  y|Y|yes|Yes|YES)
    drivessd ;;
  n|N|no|NO|No)
    diskpart
    return
  ;;
  *)
    diskpart
    return
  ;;
  esac
;;

2)
  manualpart
  diskpart
  return
;;

*)
  echo -e "\nWrong option. Try again.";
  diskpart
  return
;;

esac
}

# @description Gather username and password to be used for installation. 
userinfo () {
read -p "Please enter your username: " username
set_option USERNAME ${username,,} # convert to lower case as in issue #109 
set_password "PASSWORD"
read -rep "Please enter your hostname: " nameofmachine
set_option NAME_OF_MACHINE $nameofmachine
}

# @description Choose AUR helper. 
aurhelper () {
  # Let the user choose AUR helper from predefined list
  echo -ne "Please enter your desired AUR helper:\n"
  options=(paru yay picaur aura trizen pacaur none)
  select_option $? 4 "${options[@]}"
  aur_helper=${options[$?]}
  set_option AUR_HELPER $aur_helper
}

# @description Choose Desktop Environment
desktopenv () {
  # Let the user choose Desktop Enviroment from predefined list
  echo -ne "Please select your desired Desktop Enviroment:\n"
  options=( `for f in pkg-files/*.txt; do echo "$f" | sed -r "s/.+\/(.+)\..+/\1/;/pkgs/d"; done` )
  select_option $? 4 "${options[@]}"
  desktop_env=${options[$?]}
  set_option DESKTOP_ENV $desktop_env
}

# @description Choose whether to do full or minimal installation. 
installtype () {
  echo -ne "Please select type of installation:\n\n
  Full install: Installs full featured desktop enviroment, with added apps and themes needed for everyday use\n
  Minimal Install: Installs only apps few selected apps to get you started\n"
  options=(FULL MINIMAL)
  select_option $? 4 "${options[@]}"
  install_type=${options[$?]}
  set_option INSTALL_TYPE $install_type
}

# More features in future
# language (){}

# Starting functions
background_checks
clear
logo
userinfo
clear
logo
desktopenv
# Set fixed options that installation uses if user choses server installation
set_option INSTALL_TYPE MINIMAL
set_option AUR_HELPER NONE
if [[ ! $desktop_env == server ]]; then
  clear
  logo
  aurhelper
  clear
  logo
  installtype
fi
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
