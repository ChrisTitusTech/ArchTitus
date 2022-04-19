# ArchTitus - my Fork
**Description:**  Arch install script  
this script is from [GitHub](https://github.com/ChrisTitusTech/ArchTitus) and is modified by me

# To change
## boot
- dual boot for windows (dont delete partition)
- skip boot menu (show if 'shift' pressed down)
<!-- - do not use grub-theming -->
## package-install
- pacman-pkgs.txt
    <!-- - replace pulseaudio with pipewire -->
- GPU packages
    - check if all nessecary:
    libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
- aur-pkgs.txt
    - basically all useless -> substitute with own
- openbox.txt
- gnome.txt  
    - filter some unnessecary stuff, 
    - inspect gnome-extras (this is installed if 'FULL')
**Other:**
deepin.txt
awesome.txt
lxde.txt
cinnamon.txt
mate.txt
budgie.txt
kde.txt
xfce.txt
### services
- dont disable dhcpcd.service?

## configs:
- visudo add:
    Defaults env_keep +="PYTHONPATH"
    Defaults editor=/usr/bin/nano

### Sudo no password
just comment lines in setup.sh?
### US to DE/CH
LOCALE_IDENTIFIER="en_US.UTF-8 UTF-8"
and in `1-setup.sh` set:
`sed -i 's/^#$LOCALE_IDENTIFIER/$LOCALE_IDENTIFIER/' /etc/locale.gen`
### delete zsh
in `2-user.sh`
### turn of terminal bell/beep
## Gnome-shell-extensions
### Install 
from file
### configure
link and compile extensions from extension with gsettings according to askubuntu.com (configure gnome-shell extensions from command line)
## setup rclone with gdrived



## CleanUp
`rm -rf $AUR_HELPER`

---
# Files Structure
## archtitus.sh
**Variables:**  
`SCRIPT_DIR`  
`SCRIPTS_DIR`  
`CONFIGS_DIR`  
**Purpose:**  
runs all the other scripts

**misc:**  

## scripts/startup.sh
**Variables:**  
`CONFIG_FILE` = configs/setup.conf  

**Purpose:**  
define variables (saved to `configs/setup.conf`)

## configs/setup.conf
**Variables:**  
`FS` : Filesystem, eg: "btrfs"    
`TIMEZONE`  
`KEYMAP`  
`DISK`  
`MOUNT_OPTIONS`="noatime,compress=zstd,ssd,commit=120" #if ssd  
`USERNAME`  
`PASSWORD`  
`NAME_OF_MACHINE` : hostname  
`AUR_HELPER` : e.g: "yay"  
`DESKTOP_ENV` : e.g: "gnome"  
`INSTALL_TYPE` : in {FULL MINIMAL}, determines number of apps added  

**Purpose:**  
config file

## scripts/0-preinstall.sh
**Variables:**  
`iso` =CH  
`partition2` & `partition3`

**Purpose:**  
- optimize pacman-downloads-install 
- whipes **ALL** data/partitions (including Windows) on $DISK and creates new partition table
**misc:**  

## scripts/1-setup.sh
**Variables:**  
`TOTAL_MEM`

**Purpose:**  
- Setup / config: 
    - Network, 
    - Mirrors, 
    - n_cores (for build), 
    - Parallel Downloads, 
    - Lang&Locale  
    - sudo no password
- Installing
    - packages from `pkg-files/pacman-pkgs.txt`
    - install CPU-packages
    - install GPU-packages
    - adding user

**misc:**  

## scripts/2-user.sh
**Variables:**  

**Purpose:**  

**misc:**  

## scripts/3-post-setup.sh
**Variables:**  

**Purpose:**  

**misc:**  

---
## scripts/kderice-backup.sh
**Variables:**  

**Purpose:**  

**misc:**  

## scripts/kderice-restore.sh
**Variables:**  

**Purpose:**  

**misc:**  

