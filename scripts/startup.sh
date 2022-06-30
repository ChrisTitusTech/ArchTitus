#!/usr/bin/env bash
#github-action genshdoc
#
# @file Startup
# @brief This script will ask users about their prefrences like disk, file system, timezone, keyboard layout, user name, password, etc.
# @stdout Output routed to startup.log
# @stderror Output routed to startup.log

# Colors/formatting for echo
  BOLD='\e[1m'
  RESET='\e[0m' # Reset text to default appearance
#   High intensity colors:
    BRED='\e[91m'

# @setting-header General Settings
# @setting CONFIG_FILE string[$CONFIGS_DIR/setup.conf] Location of setup.conf to be used by set_option and all subsequent scripts.
CONFIG_FILE=$CONFIGS_DIR/setup.conf
[ -f $CONFIG_FILE ] || touch -f $CONFIG_FILE # create $CONFIG_FILE if it doesn't exist

# @description set options in setup.conf
# @arg $1 string Configuration variable.
# @arg $2 string Configuration value.
set_option() {
    grep -Eq "^${1}.*" $CONFIG_FILE && sed -i "/^${1}.*/d" $CONFIG_FILE # delete option if exists
    echo "${1}=${2}" >>$CONFIG_FILE # add option
}
# @description Renders a text based list of options that can be selected by the
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
                        [[ $key = ""      ]] && echo enter
                        [[ $key = $'\x20' ]] && echo space
                        [[ $key = "k" ]] && echo up
                        [[ $key = "j" ]] && echo down
                        [[ $key = "h" ]] && echo left
                        [[ $key = "l" ]] && echo right
                        [[ $key = "a" ]] && echo all
                        [[ $key = "n" ]] && echo none
                        if [[ $key = $'\x1b' ]]; then
                            read -rsn2 key
                            [[ $key = [A || $key = k ]] && echo up
                            [[ $key = [B || $key = j ]] && echo down
                            [[ $key = [C || $key = l ]] && echo right
                            [[ $key = [D || $key = h ]] && echo left
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
            [ $idx -eq $curr_idx ] && print_selected "$option" || print_option "$option"
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
                    [ $active_row -lt 0 ] && active_row=0;;
            down)   ((active_row++));
                    [ $active_row -ge $(( ${#options[@]} / $colmax ))  ] && active_row=$(( ${#options[@]} / $colmax ));;
            left)     ((active_col=$active_col - 1));
                    [ $active_col -lt 0 ] && active_col=0;;
            right)     ((active_col=$active_col + 1));
                    [ $active_col -ge $colmax ] && active_col=$(( $colmax - 1 ))
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
echo "
-------------------------------------------------------------------------
 █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
------------------------------------------------------------------------
            Please select presetup settings for your system
------------------------------------------------------------------------"
}
# @description This function will handle file systems. At this movement we are handling only
# btrfs and ext4. Others will be added in future.
filesystem () {
echo "
Please select your file system for both boot and root:"
options=("btrfs" "ext4" "luks" "exit")
select_option $? 1 "${options[@]}"

case $? in
0) set_option FS btrfs;;
1) set_option FS ext4;;
2)
while true; do
  read -r -s -p "Please enter your luks password: " luks_password # read password without echo
  echo
  read -r -s -p "Please repeat your luks password: " luks_password2 # read password without echo
  echo

  if [ "$luks_password" = "$luks_password2" ]; then
    set_option LUKS_PASSWORD $luks_password
    set_option FS luks
    break
  else
    echo -e "\nPasswords do not match. Please try again. \n"
  fi
done
;;
3) exit ;;
*) echo "Wrong option please select again"; filesystem;;
esac
}
# @description Detects and sets timezone.
timezone () {
# Added this from arch wiki https://wiki.archlinux.org/title/System_time
time_zone="$(curl --fail https://ipapi.co/timezone)"
echo "
System detected your timezone to be '$time_zone' "
echo "Is this correct?"
options=("Yes" "No")
select_option $? 1 "${options[@]}"

case ${options[$?]} in
    y|Y|yes|Yes|YES)
    echo "${time_zone} set as timezone"
    set_option TIMEZONE $time_zone;;
    n|N|no|NO|No)
    read -p "Please enter your desired timezone e.g. Europe/London: " new_timezone
    echo "${new_timezone} set as timezone"
    set_option TIMEZONE $new_timezone;;
    *) echo "Wrong option. Try again";timezone;;
esac
}
# @description Set user's keyboard mapping.
keymap () {
echo -n "
Please select a keyboard layout from this list:"
# These are default key maps as presented in official arch repo archinstall
options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru sg ua uk)

select_option $? 4 "${options[@]}"
keymap=${options[$?]}

echo "Chosen keyboard layout: ${keymap}"
set_option KEYMAP $keymap
}

# @description Choose whether drive is SSD or not.
drivessd () {
echo "
Is this an ssd? yes/no:"

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

# @description Disk selection for drive to be used with installation.
diskpart () {
echo -e "
------------------------------------------------------------------------
    ${BRED}${BOLD}THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK!${RESET}
    Please make sure you know what you are doing because
    after formating your disk there is no way to get data back
------------------------------------------------------------------------
"

PS3='
Select the disk to install on: '
options=($(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}'))

select_option $? 1 "${options[@]}"
disk=${options[$?]%|*}

echo -e "\n${disk%|*} selected \n"
    set_option DISK ${disk%|*}

drivessd
}

# @description Gather username and password to be used for installation.
userinfo () {
read -p "Please enter your username: " username
set_option USERNAME ${username,,} # convert to lower case as in issue #109
while true; do
  read -r -s -p "Please enter your password: " password # read password without echo
  echo
  read -r -s -p "Please repeat your password: " password2 # read password without echo
  echo

  if [ "$password" = "$password2" ]; then
    set_option PASSWORD $password
    break
  else
    echo -e "\nPasswords do not match. Please try again. \n"
  fi
done
read -rep "Please enter your hostname: " nameofmachine
set_option NAME_OF_MACHINE $nameofmachine
}

# @description Choose AUR helper.
aurhelper () {
  # Let the user choose AUR helper from predefined list
  echo "Please enter your desired AUR helper:"
  options=(paru yay picaur aura trizen pacaur none)
  select_option $? 4 "${options[@]}"
  aur_helper=${options[$?]}
  set_option AUR_HELPER $aur_helper
}

# @description Choose Desktop Environment
desktopenv () {
  # Let the user choose Desktop Enviroment from predefined list
  echo "Please select your desired Desktop Enviroment:"
  options=(gnome kde cinnamon xfce mate budgie lxde deepin openbox server)
  select_option $? 4 "${options[@]}"
  desktop_env=${options[$?]}
  set_option DESKTOP_ENV $desktop_env
}

# @description Choose whether to do full or minimal installation.
installtype () {
  echo -e "Please select type of installation:\n\n
  Full install: Installs full featured desktop enviroment, with added apps and themes needed for everyday use\n
  Minimal Install: Installs only a few selected apps to get you started"
  options=(FULL MINIMAL)
  select_option $? 4 "${options[@]}"
  install_type=${options[$?]}
  set_option INSTALL_TYPE $install_type
}

# More features in future
# language (){}

# Starting functions
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
