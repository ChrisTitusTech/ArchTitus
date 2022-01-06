#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
#  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
#  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
#  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
#-------------------------------------------------------------------------
echo "--------------------------------------"
echo "--          Network Setup           --"
echo "--------------------------------------"
pacman -S networkmanager dhclient --noconfirm --needed
systemctl enable --now NetworkManager
echo "-------------------------------------------------"
echo "Setting up mirrors for optimal download          "
echo "-------------------------------------------------"
pacman -S --noconfirm pacman-contrib curl
pacman -S --noconfirm reflector rsync
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak

nc=$(grep -c ^processor /proc/cpuinfo)
echo "You have " $nc" cores."
echo "-------------------------------------------------"
echo "Changing the makeflags for "$nc" cores."
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -gt 8000000 ]]; then
sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
echo "Changing the compression settings for "$nc" cores."
sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
fi
echo "-------------------------------------------------"
echo "       Setup Language to US and set locale       "
echo "-------------------------------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-timezone America/Chicago
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_US.UTF-8" LC_TIME="en_US.UTF-8"

# Set keymaps
localectl --no-ask-password set-keymap us

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

#Add parallel downloading
sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

#Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm

echo -e "\nInstalling Base System\n"

PKGS=(
'mesa' # Essential Xorg First - An open-source implementation of the OpenGL specification
'xorg' # Display Server Meta Package
'xorg-server' # Display Server
'xorg-apps' # Applications for xorg Display Server
'xorg-drivers' # Video Drivers
'xorg-xkill' # Tools to Kill X Processes
'xorg-xinit' # Program to manually start X Display Server
'xterm' # Standard Terminal Emulator
'plasma-desktop' # KDE Load second
'alsa-plugins' # Audio Plugins
'alsa-utils' # Audio Utilities
'ark' # File Compression
'audiocd-kio' # KDE Audio CD Reading
'autoconf' # A GNU tool for automatically configuring source code
'automake' # A GNU tool for automatically creating Makefiles
'base' # Minimal package set to define a basic Arch Linux installation
'bash-completion' # Tab Complete commands, filenames, variables
'bind' # DNS Server
'binutils' # A set of programs to assemble and manipulate binary and object files
'bison' # GNU Parser Generator - Compiler
'bluedevil' # Bluetooth tech for KDE
'bluez' # Bluetooth Daemons
'bluez-libs' # Deprecated libraries for the bluetooth protocol stack
'bluez-utils' # Development and debugging utilities for the bluetooth protocol stack
'breeze' # Theme for KDE Plasma
'breeze-gtk' # Widget Theme 
'bridge-utils' # Utilities for configuring the Linux ethernet bridge
'btrfs-progs' # Btrfs filesystem utilities
'celluloid' # Video Player - MPV Frontend
'cmatrix' # Scrolling Lines from Matrix Movie
'code' # Visual Studio code
'cronie' # Daemon that runs specified programs at scheduled times and related tools
'cups' # Open Source Printing System
'dialog' # A tool to display dialog boxes from shell scripts
'discover' # KDE and Plasma resources management GUI
'dolphin' # Default File Manager for KDE
'dosfstools' # DOS filesystem utilities
'dtc' # Device Tree Compiler
'efibootmgr' # EFI boot
'egl-wayland' # EGLStream-based Wayland external platform - Video Driver Stuff
'exfatprogs' # Utilities for exFAT file system
'extra-cmake-modules' # Extra modules and scripts for CMake (A cross-platform open-source make system)
'filelight' # View disk usage information
'flex' # Tool for generating scanners: programs which recognize lexical patterns in text (For Compilers)
'fuse2' # A library that makes it possible to implement a filesystem in a userspace program (Filesystem in userspace) 
'fuse3' # A library that makes it possible to implement a filesystem in a userspace program (Filesystem in userspace) 
'fuseiso' # FUSE module to let unprivileged users mount ISO filesystem images 
'gamemode' # daemon/lib combo for Linux that allows games to request a set of optimisations be temporarily applied to the host OS and/or a game process
'gcc' # GNU Compiler Collection - C and C++ frontends
'gimp' # Photo editing
'git' # Version Control System to Maintain AUR Packages
'gparted' # A Partition Magic clone, frontend to GNU Parted
'gptfdisk' # A text-mode partitioning tool that works on GUID Partition Table (GPT) disks
'grub' # GNU GRand Unified Bootloader
'grub-customizer' # A graphical grub2 settings manager
'gst-libav' # Multimedia graph framework - libav plugin
'gst-plugins-good' # Multimedia graph framework - good plugins
'gst-plugins-ugly' # Multimedia graph framework - ugly plugins
'gwenview' # Image Viewer
'haveged' # Random Number Generator
'htop' # Interactive process viewer
'iptables-nft' # Linux kernel packet control tool (using nft interface)
'jdk-openjdk' # Java 17
'kate' # Gui Text Editor
'kcodecs' # Provide a collection of methods to manipulate strings using various encodings -KDE
'kcoreaddons' # Addons to QtCore -KDE
'kdeplasma-addons' # All kind of addons to improve your Plasma experience
'kde-gtk-config' # GTK2 and GTK3 Configurator for KDE
'kinfocenter' # A utility that provides information about a computer system
'kscreen' # KDE screen management software
'kvantum-qt5' # SVG-based theme engine for Qt5 (including config tool and extra themes)
'kitty' # OpenGL based terminal emulator with TrueColor, ligatures support, protocol extensions for keyboard input and image rendering
'konsole' # KDE terminal emulator
'layer-shell-qt' # Qt component to allow applications to make use of the Wayland wl-layer-shell protocol
'libdvdcss' # Portable abstraction library for DVD decryption
'libnewt' # Not Erik's Windowing Toolkit - text mode windowing with slang
'libtool' # A generic library support script
'linux' # The Linux kernel and modules
'linux-firmware' # Firmware files for Linux
'linux-headers' # Headers and scripts for building modules for the Linux kernel
'lsof' # Lists open files for running Unix processes
'lutris' # Open Gaming Platform
'lzop' # File Compressor very similar to gzip
'm4' # The GNU macro processor
'make' # GNU make utility to maintain groups of programs
'milou' # A dedicated search application built on top of Baloo
'nano' # Command Line Text Editor
'neofetch' # A CLI system information tool written in BASH that supports displaying images
'networkmanager' # Network connection manager and user applications
'ntfs-3g' # NTFS filesystem driver and utilities
'ntp' # Network Time Protocol reference implementation
'okular' # GUI Document Viewer
'openbsd-netcat' # TCP/IP swiss army knife. OpenBSD variant
'openssh' # SSH remote login server
'os-prober' # Utility to detect other OSes on a set of drives
'oxygen' # KDE Style
'p7zip' # Command-line file archiver with high compression ratio
'pacman-contrib' # Contributed scripts and tools for pacman systems
'patch' # A utility to apply patch files to original sources
'picom' # X compositor that may fix tearing issues
'pkgconf' # Package compiler and linker metadata toolkit
'plasma-meta' # Meta package to install KDE Plasma
'plasma-nm' # Plasma applet written in QML for managing network connections
'powerdevil' # Manages the power consumption settings of a Plasma Shell
'powerline-fonts' # patched fonts for powerline
'print-manager' # A tool for managing print jobs and printers
'pulseaudio' # A featureful, general-purpose sound server
'pulseaudio-alsa' # Advanced Linux Sound Architecture (ALSA) Configuration for PulseAudio
'pulseaudio-bluetooth' # Bluetooth support for PulseAudio
'python-notify2' # Python interface to DBus notifications
'python-psutil' # A cross-platform process and system utilities module for Python
'python-pyqt5' # A set of Python bindings for the Qt5 toolkit
'python-pip' # The PyPA recommended tool for installing Python packages
'qemu' # A generic and open source machine emulator and virtualizer
'rsync' # A fast and versatile file copying tool for remote and local files
'sddm' # QML based X11 and Wayland display manager
'sddm-kcm' # KDE Config Module for SDDM
'snapper' # A tool for managing BTRFS and LVM snapshots. It can create, diff and restore snapshots and provides timelined auto-snapping.
'spectacle' # KDE screenshot capture utility
'steam' # Valve's digital software delivery system - Games
'sudo' # Give certain users the ability to run some commands as root
'swtpm' # Libtpms-based TPM emulator with socket, character device, and Linux CUSE interface
'synergy' # Share a single mouse and keyboard between multiple computers
'systemsettings' # KDE system manager for hardware, software, and workspaces
'terminus-font' # Monospace bitmap font (for X11 and console)
'traceroute' # Tool to track the route taken by packets over an IP network
'ufw' # Uncomplicated and easy to use CLI tool for managing a netfilter firewall
'unrar' # The RAR uncompression program
'unzip' # For extracting and viewing files in .zip archives
'usbutils' # A collection of USB tools to query connected USB devices
'vim' # Vi Improved, a highly configurable, improved version of the vi text editor
'virt-manager' # Desktop user interface for managing virtual machines
'virt-viewer' # A lightweight interface for interacting with the graphical display of virtualized guest OS.
'wget' # Network utility to retrieve files from the Web
'which' # A utility to show the full path of commands
'wine-gecko' # Wine's built-in replacement for Microsoft's Internet Explorer
'wine-mono' # Wine's built-in replacement for Microsoft's .NET Framework
'winetricks' # Script to install various redistributable runtime libraries in Wine.
'xdg-desktop-portal-kde' # A backend implementation for xdg-desktop-portal using Qt/KF5
'xdg-user-dirs' # Manage user directories like ~/Desktop and ~/Music
'zeroconf-ioslave' # Network Monitor for DNS-SD services (Zeroconf)
'zip' # Compressor/archiver for creating and modifying zipfiles
'zsh' # A very advanced and programmable command interpreter (shell) for UNIX
'zsh-syntax-highlighting' # Fish shell like syntax highlighting for Zsh
'zsh-autosuggestions' # Fish-like autosuggestions for zsh
)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    sudo pacman -S "$PKG" --noconfirm --needed
done

#
# determine processor type and install microcode
# 
proc_type=$(lscpu | awk '/Vendor ID:/ {print $3}')
case "$proc_type" in
	GenuineIntel)
		print "Installing Intel microcode"
		pacman -S --noconfirm intel-ucode
		proc_ucode=intel-ucode.img
		;;
	AuthenticAMD)
		print "Installing AMD microcode"
		pacman -S --noconfirm amd-ucode
		proc_ucode=amd-ucode.img
		;;
esac	

# Graphics Drivers find and install
if lspci | grep -E "NVIDIA|GeForce"; then
    pacman -S nvidia --noconfirm --needed
	nvidia-xconfig
elif lspci | grep -E "Radeon"; then
    pacman -S xf86-video-amdgpu --noconfirm --needed
elif lspci | grep -E "Integrated Graphics Controller"; then
    pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils --needed --noconfirm
fi

echo -e "\nDone!\n"
if ! source install.conf; then
	read -p "Please enter username:" username

# Make username lowercase
username=${username,,}

echo "username=$username" >> ${HOME}/ArchTitus/install.conf
fi
if [ $(whoami) = "root"  ];
then
    useradd -m -G wheel,libvirt -s /bin/bash $username 
	passwd $username
	cp -R /root/ArchTitus /home/$username/
    chown -R $username: /home/$username/ArchTitus
	read -p "Please name your machine:" nameofmachine
	echo $nameofmachine > /etc/hostname
else
	echo "You are already a user proceed with aur installs"
fi

