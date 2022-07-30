# Startup

This script will ask users about their prefrences like disk, file system, timezone, keyboard layout, user name, password, etc.

# Settings

## General Settings
* **CONFIG_FILE** (string)[default: **$CONFIGS_DIR/setup.conf**]: Location of setup.conf to be used by set_option and all subsequent scripts. 


# Functions
* [set_option()](#set_option)
* [logo()](#logo)
* [filesystem()](#filesystem)
* [timezone()](#timezone)
* [keymap()](#keymap)
* [drivessd()](#drivessd)
* [diskpart()](#diskpart)
* [userinfo()](#userinfo)
* [aurhelper()](#aurhelper)
* [desktopenv()](#desktopenv)
* [installtype()](#installtype)


## set_option()

set options in setup.conf

### Output on stdout

* Output routed to startup.log

### Output on stderr

* # @stderror Output routed to startup.log

### Arguments

* **$1** (string): Configuration variable.

### Arguments

* **$2** (string): Configuration value.

## logo()

Displays ArchTitus logo

_Function has no arguments._

## filesystem()

This function will handle file systems. At this movement we are handling only
btrfs and ext4. Others will be added in future.

## timezone()

Detects and sets timezone. 

## keymap()

Set user's keyboard mapping. 

## drivessd()

Choose whether drive is SSD or not.

## diskpart()

Disk selection for drive to be used with installation.

## userinfo()

Gather username and password to be used for installation. 

## aurhelper()

Choose AUR helper. 

## desktopenv()

Choose Desktop Environment

## installtype()

Choose whether to do full or minimal installation. 


