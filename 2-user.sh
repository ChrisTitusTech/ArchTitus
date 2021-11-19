#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
#  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
#  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
#  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
#-------------------------------------------------------------------------

echo "-------------------------------------------------------------------------"
echo "--            Setup yay to download packages from AUR                  --"
echo "-------------------------------------------------------------------------"
# Make sure these packages are installed for installing AUR manager
sudo pacman -S git base-devel --noconfirm --needed

# Download and Install yay AUR manager
cd ~
git clone "https://aur.archlinux.org/yay.git"
cd ${HOME}/yay
makepkg -si --noconfirm


echo "-------------------------------------------------------------------------"
echo "--               Installing Requested Packages from AUR                --"
echo "-------------------------------------------------------------------------"
PKGS_AUR_CORE=(
'autojump' # A faster way to navigate your filesystem from the command line
'awesome-terminal-fonts'
'lightly-git' # theme (for qt)
'lightlyshaders-git'
'nerd-fonts-fira-code'
'nordic-darker-standard-buttons-theme'
'nordic-darker-theme'
'nordic-kde-git'
'nordic-theme'
'noto-fonts-emoji'
'papirus-icon-theme'
'plasma-pa'
'ocs-url' # install packages from websites
'sddm-nordic-theme-git'
'ttf-droid'
'ttf-hack'
'ttf-meslo' # Nerdfont package
'ttf-roboto'
)

PKGS_AUR_DEFAULT=(
'brave-bin' # Brave Browser
'dxvk-bin' # DXVK DirectX to Vulcan
'github-desktop-bin' # Github Desktop sync
'mangohud' # Gaming FPS Counter
'mangohud-common' #installs with mangohud
'zoom' # video conferences
'snap-pac' # btrfs tools...runs snapshot after every pacman install
'snapper-gui-git' # a tool of managing snapshots of Btrfs subvolumes and LVM volumes
)

# install core packages
for PKG in "${PKGS_AUR_CORE[@]}"; do
	echo "INSTALLING AUR CORE PACKAGE: ${PKG}"
    yay -S --noconfirm $PKG
done

# Read config file, if it exists
configFileName=${HOME}/ArchTitus/install.conf
if [ -e "$configFileName" ]; then
	echo "Using configuration file $configFileName."
	. $configFileName
fi

# install default or user specified packages (if they exist)
if [ ${#PKGS_AUR[@]} -eq 0 ]; then
	echo "installing AUR default packages"
	for PKG in "${PKGS_AUR_DEFAULT[@]}"; do
	    echo "INSTALLING AUR DEFAULT PACKAGE: ${PKG}"
		yay -S --noconfirm $PKG
	done
else
	echo "installing AUR user specified packages"
	for PKG in "${PKGS_AUR[@]}"; do
	    echo "INSTALLING AUR USER SPECIFIED PACKAGE: ${PKG}"
		yay -S --noconfirm $PKG
	done
fi


echo "-------------------------------------------------------------------------"
echo "--                        Setup User Theme                             --"
echo "-------------------------------------------------------------------------"
# Zsh syntax highlighting
cd ~
touch "$HOME/.cache/zshhistory"
git clone "https://github.com/ChrisTitusTech/zsh"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/powerlevel10k
ln -s "$HOME/zsh/.zshrc" $HOME/.zshrc

# KDE config
sudo pacman -S python-pip --noconfirm --needed
export PATH=$PATH:~/.local/bin
cp -r $HOME/ArchTitus/dotfiles/* $HOME/.config/
pip install konsave
konsave -i $HOME/ArchTitus/kde.knsv
sleep 1
konsave -a kde

sudo systemctl enable sddm.service
sudo bash -c 'cat <<EOF > /etc/sddm.conf
[Theme]
Current=Nordic
[General]
InputMethod=qtvirtualkeyboard
EOF
'

# In case someone uses 
'$HOME/.config/dolphinrc'

# In case someone installs syncthing
username=$(whoami)
systemctl enable syncthing@$username.service

# In case someone doesn't delete ffmpegthumbs (video thumbnails)
# This is dolphin defaults + ffmpegthumbs
echo "[PreviewSettings]" >> $HOME/.config/dolphinrc
echo "Plugins=appimagethumbnail,audiothumbnail,comicbookthumbnail,cursorthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,windowsexethumbnail,windowsimagethumbnail,opendocumentthumbnail,svgthumbnail,textthumbnail,ffmpegthumbs" >> $HOME/.config/dolphinrc
echo "[PreviewSettings]" >> $HOME/.config/kdeglobals
echo "MaximumRemoteSize=10485758951424" >> $HOME/.config/kdeglobals

#echo "[General]" >> $HOME/.config/dolphinrc
#echo "RememberOpenedTabs=false" >> $HOME/.config/dolphinrc

echo "ready for 'arch-chroot /mnt /root/ArchTitus/3-post-setup.sh'"
