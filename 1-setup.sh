#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
#  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
#  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
#  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
#-------------------------------------------------------------------------

ISO=$(curl -4 ifconfig.co/country-iso)
echo "-------------------------------------------------------------------------"
echo "--                  Changes for optimal downloading                    --"
echo "-------------------------------------------------------------------------"
#commented because we just did this..
#pacman -S --noconfirm reflector rsync
#cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
#reflector -a 48 -c $ISO -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

# Add parallel downloading
sed -i 's/^#Para/Para/' /etc/pacman.conf

# Enable multilib
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm


nc=$(grep -c ^processor /proc/cpuinfo)
echo "-------------------------------------------------------------------------"
echo "--               Changing the makeflags for "$nc" core(s).                 --"
echo "-------------------------------------------------------------------------"
TOTALMEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
if [[  $TOTALMEM -gt 8000000 ]]; then
	sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j$nc\"/g" /etc/makepkg.conf
	echo "Changing the compression settings for "$nc" cores."
	sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T $nc -z -)/g" /etc/makepkg.conf
fi


echo "-------------------------------------------------------------------------"
echo "--               Setup Language to US and set locale                   --"
echo "-------------------------------------------------------------------------"
timezone=$(curl -4 http://ip-api.com/line?fields=timezone)
locale=en_US.UTF-8

# Set locale
sed -i s/^#$locale/$locale/ /etc/locale.gen
locale-gen
echo LANG=$locale  > /etc/locale.conf
localectl --no-ask-password set-locale LANG=$locale LC_TIME=$locale

# Set time
timedatectl --no-ask-password set-ntp 1
timedatectl --no-ask-password set-timezone $timezone
#ln -sf /usr/share/zoneinfo/$timezone /etc/localtime

# Set keymaps
localectl --no-ask-password set-keymap us
#echo "KEYMAP=US" > /etc/vconsole.conf
    
# Set timezone when NetworkManager connects to a network
file=/etc/NetworkManager/dispatcher.d/09-timezone.sh
cat <<EOF > $file
#!/bin/sh
case "\$2" in
    up)
    	timezone=\$(curl --fail http://ip-api.com/line?fields=timezone)
        timedatectl --no-ask-password set-timezone \$timezone
	#ln -sf /usr/share/zoneinfo/\$timezone /etc/localtime
    ;;
esac
EOF
chmod +x $file


echo "-------------------------------------------------------------------------"
echo "--                    X Display Manager Setup                          --"
echo "-------------------------------------------------------------------------"
pacman -S xorg --noconfirm --needed


echo "-------------------------------------------------------------------------"
echo "--                        KDE Plasma Setup                             --"
echo "-------------------------------------------------------------------------"
pacman -S plasma dolphin --noconfirm --needed
pacman -S packagekit-qt5 --noconfirm --needed #needed for discover, which is in the plasma group
pacman -S kdialog --noconfirm --needed #needed for some apps to display native kde dialogs
pacman -S ffmpegthumbs --noconfirm --needed #needed for video thumbnails in dolphin, can turn off in dolphin options


echo "-------------------------------------------------------------------------"
echo "--                  Installing Requested Packages                      --"
echo "-------------------------------------------------------------------------"
PKGS_ARCH_DEFAULT=(

#...THEME...
'terminus-font'
'powerline-fonts'

#...TOOLS...
'usbutils' # query connected USB devices
'ntp' # network time protocol reference implementation

#...NETWORK TOOLS...
'bridge-utils' # configuring etnernet bridge
'iptables-nft' # replaces iptables
'traceroute' # track route taken by packets over an IP network
'openbsd-netcat' # tcp/ip network tools
'bind' # DNS tools
'gufw' # manage netfilter firewall

#...MAIN TOOLS...
'cmatrix' # matrix screen
'cronie' # schedule tasks/jobs
'htop' # see running processes
'dmidecode' # see system technical specs
'lsof' # list open files for running Unix processes
'nano' # a famous text editor...easy for newbies, not as powerful as vim
'neofetch' # displays information about your computer
'openssh' # remote login another system with the SSH protocol
'os-prober' # detect other OSes on a set of drives (for grub)
'vim' # a famous text editor...hard for newbies
'wget' # get files from web
'git' # get files from web, think github or gitlab
'bash-completion' # programmable completion for the bash shell
'zsh' # command line interpreter
	'zsh-syntax-highlighting'
	'zsh-autosuggestions'
	'zsh-completions'
'pacman-contrib' # scripts and tools for pacman systems
'rsync' # sync files
'reflector' # sort and filter pacman mirror list
'snapper' # managing BTRFS and LVM snapshots tool...(installed by snap-pac and snapper-gui-git as well)

#...KDE...
#'qt5-virtualkeyboard' # Virtual keyboard for login screen (surface devices)
'konsole' # KDE terminal
'kate' # KDE text editor
'ark' # KDE file archive tool
	'p7zip'      # 7Z format support 
	'unrar'      # RAR decompression support
	'unarchiver' # RAR format support
	'lzop'       # LZO format support
	'lrzip'      # LRZ format support
'gwenview' # KDE image viewer
	'qt5-imageformats' # tiff, webp and more formats
	'kimageformats'	   # dds, xcf, exr, psd, and more formats
	'kipi-plugins'     # export to various online services
	'kamera'           # imports from gphoto2 cameras
'filelight' # KDE tool to view disk use
'spectacle' # KDE screenshot capture utility
	'kipi-plugins' # export to various online services

#...MISC/OTHER...
'picom' # X compositor that may fix tearing issues
'gparted' # graphical partition management
'grub-customizer' # gui to customize grub
'kitty' # terminal
'celluloid' # video players
'code' # Visual Studio code
'gimp' # Photo editing
'jdk-openjdk' # Java 17
'lutris' # gaming platform
'okular' # pdf viewer
'qemu' # a hypervisor (virtual machines)
'steam' # games
'gamemode' # gaming optimizations
'synergy' # share kebyard and mouse amung systems
'virt-manager' # another hypervisor (create virtual machines)
'virt-viewer' # another hypervisor (view virtual machines)
'wine-gecko' # Wine's built-in replacement for Microsoft's Internet Explorer...(also installs wine)
'wine-mono' # Wine's built-in replacement for Microsoft's .NET Framework...(also installs wine)
'winetricks' # makes wine better...(also installs wine)

#...AUDIO/SOUND SUPPORT...
'alsa-plugins' #(installed by steam)
'alsa-utils'
'pulseaudio' #(installed as part of plasma-pa)
'pulseaudio-alsa'
'pulseaudio-bluetooth'

#...POWER/BATTERY/SUSPEND SUPPORT...
'powerdevil' # KDE tool to manage power consumption...(installed as part of plasma-desktop)

#...BLUETOOTH SUPPORT...
'bluedevil'
'bluez' # bluetooth support...(installed as part of bluedevil and powerdevil)
'bluez-libs'  #(installed as part of networkmanager)
'bluez-utils'

#...PRINTER SUPPORT...
'cups' # printer support
'print-manager' # KDE tool to manage printers

#...FILESYSTEM SUPPORT...
'ntfs-3g' # NTFS support
'dosfstools' #(installed by kde things)
'exfat-utils' # exfat support
'btrfs-progs' #(installed by snap-pac and snapper-gui-git MIGHT MIGHT Be installed by kde things)
'fuseiso' # mount ISO images

#...SAMBA-WINDOWS NETWORK SHARE SUPPORT...
#'samba'
#'smbnetfs'

#...UNNEEDED to explicitly install...
'unzip' # file compression installed by other things when needed as a dependency
'zip' # file compression
'audiocd-kio' # Audio CDs
'swtpm' # small tpm emulator
'dialog' # Shows a dialog by command line
'dtc'  # Device Tree Compilier (required for qemu and spike a ISA emulator)
'egl-wayland' # graphics/nvidia
'extra-cmake-modules' # installs by others things when needed as a dependency
'fuse2'  #(installed as part of fuseiso)
'fuse3'  #(installed as part of plasma-worksapce)
'gptfdisk' #DOES CFDISK work without it? YES  (installed as part of a bunch of kde things)
'kcoreaddons' #(installed as part of a bunch of kde things)
'zeroconf-ioslave' # network Monitor for DNS-SD services for KDE
'kvantum-qt5' 
'linux-firmware'
'linux-headers'
'python-notify2'
'python-psutil'
'python-pyqt5'
#CODECS
'gst-libav' #installed as part of wine dxvk-bin I DID NOT INSTALL WINE..its DXVK-BIN
'gst-plugins-good'  #(installed by virt)
'gst-plugins-ugly'
'libdvdcss' # Portable abstraction library for DVD decryption
'kcodecs' #(installed as part of a bunch of kde things)
)

# Read config file, if it exists
configFileName=${HOME}/ArchTitus/install.conf
if [ -e "$configFileName" ]; then
	echo "Using configuration file $configFileName."
	. $configFileName
fi

# install default or user specified packages (if they exist)
if [ ${#PKGS_ARCH[@]} -eq 0 ]; then
	echo "installing arch default packages"
	for PKG in "${PKGS_ARCH_DEFAULT[@]}"; do
	    echo "INSTALLING ARCH DEFAULT PACKAGE: ${PKG}"
	    pacman -S "$PKG" --noconfirm --needed
	done
else
	echo "installing arch user specified packages"
	for PKG in "${PKGS_ARCH[@]}"; do
	    echo "INSTALLING ARCH USER SPECIFIED PACKAGE: ${PKG}"
	    pacman -S "$PKG" --noconfirm --needed
	done
fi

echo "-------------------------------------------------------------------------"
echo "--                 Installing Processor Microcode                      --"
echo "-------------------------------------------------------------------------"
proc_type=$(lscpu | awk '/Vendor ID:/ {print $3}')
case "$proc_type" in
	GenuineIntel)
		echo "Installing Intel microcode"
		pacman -S --noconfirm intel-ucode
		proc_ucode=intel-ucode.img
		;;
	AuthenticAMD)
		echo "Installing AMD microcode"
		pacman -S --noconfirm amd-ucode
		proc_ucode=amd-ucode.img
		;;
esac	


echo "-------------------------------------------------------------------------"
echo "--                   Installing Grapics Drivers                        --"
echo "-------------------------------------------------------------------------"
if lspci | grep -E "NVIDIA|GeForce"; then
	echo "Installing NVIDIA Drivers."
    	pacman -S nvidia --noconfirm --needed
	nvidia-xconfig
elif lspci | grep -E "Radeon"; then
    	echo "Installing ATI/AMD Drivers."
	pacman -S xf86-video-amdgpu --noconfirm --needed
elif lspci | grep -E "Integrated Graphics Controller"; then
    	echo "Installing Intel Integrated Drivers."
    	pacman -S libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils --needed --noconfirm
fi

hypervisor=$(systemd-detect-virt)
case $hypervisor in
kvm )		echo "Installing KVM guest tools."
		pacman -S qemu-guest-agent --noconfirm --needed
		systemctl enable qemu-guest-agent
		;;
vmware )   	echo "Installing VMWare guest tools."
	    	pacman -S open-vm-tools --noconfirm --needed
	    	systemctl enable vmtoolsd
	    	systemctl enable vmware-vmblock-fuse
	    	;;
oracle )    	echo "Installing VirtualBox guest tools."
	    	pacman -S virtualbox-guest-utils --noconfirm --needed
		systemctl enable vboxservice
	    	;;
microsoft ) 	echo "Installing Hyper-V guest tools."
		pacman -S hyperv --noconfirm --needed
	    	systemctl enable hv_fcopy_daemon
	    	systemctl enable hv_kvp_daemon
	    	systemctl enable hv_vss_daemon
	    	;;
esac


echo "-------------------------------------------------------------------------"
echo "--                            Setup User                               --"
echo "-------------------------------------------------------------------------"
# Read config file, if it exists
configFileName=${HOME}/ArchTitus/install.conf
if [ -e "$configFileName" ]; then
	echo "Using configuration file $configFileName."
	. $configFileName
fi

# Get username
if [ -e "$configFileName" ] && [ ! -z "$username" ]; then
	echo "Creating user - $username."
else
	read -p "Please enter username:" username
	echo "username=$username" >> $configFileName
fi

# Add user
egrep -i "libvirt" /etc/group;
if [ $? -eq 0 ]; then
	useradd -m -G wheel,libvirt -s /bin/bash $username
else
	useradd -m -G wheel -s /bin/bash $username
fi

# Set user password
if [ -e "$configFileName" ] && [ ! -z "$password" ] && [ "$password" != "*!*CHANGEME*!*...and-dont-store-in-plantext..." ]; then
	echo "Got a password for $username."
	echo "$username:$password" | chpasswd
	echo "Masking password in config file."
	sed -i.bak 's/^\(password=\).*/\1*!*CHANGEME*!*...and-dont-store-in-plantext.../' $configFileName
else
	passwd $username
	if [ "$password" != "*!*CHANGEME*!*...and-dont-store-in-plantext..." ]; then
		echo "password=*!*CHANGEME*!*...and-dont-store-in-plantext..." >> $configFileName
	fi
fi

# Set hostname
if [ -e "$configFileName" ] && [ ! -z "$hostname" ]; then
	echo "hostname: $hostname"
else
	read -p "Please name your machine:" hostname
	echo "hostname=$hostname" >> $configFileName
fi
echo $hostname > /etc/hostname

# Set hosts file.
cat <<EOF > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

# Copy this script to new user home directory
cp -R /root/ArchTitus /home/$username/
chown -R $username: /home/$username/ArchTitus

# Add sudo no password rights
sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

echo "ready for 'arch-chroot /mnt /usr/bin/runuser -u $username -- /home/$username/ArchTitus/2-user.sh'"
