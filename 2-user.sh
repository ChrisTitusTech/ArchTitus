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

# ffmpegthumbs (video thumbnails) for Dolphin
# This is dolphin defaults + ffmpegthumbs
echo "[PreviewSettings]" >> $HOME/.config/dolphinrc
echo "Plugins=appimagethumbnail,audiothumbnail,comicbookthumbnail,cursorthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,windowsexethumbnail,windowsimagethumbnail,opendocumentthumbnail,svgthumbnail,textthumbnail,ffmpegthumbs" >> $HOME/.config/dolphinrc
echo "[PreviewSettings]" >> $HOME/.config/kdeglobals
echo "MaximumRemoteSize=10485758951424" >> $HOME/.config/kdeglobals

#echo "[General]" >> $HOME/.config/dolphinrc
#echo "RememberOpenedTabs=false" >> $HOME/.config/dolphinrc

# install optional weather package if configured
if [ ! -z "${openWeatherMapCityId}" ]; then
    if [ -z "${openWeatherMapCityAlias}" ]; then
        openWeatherMapCityAlias="Configured City"
    fi
    echo "configuring weather for $openWeatherMapCityAlias - $openWeatherMapCityId"

    # Install plasmoids
    yay -S --noconfirm plasma5-applets-eventcalendar

    cd ~
    git clone https://github.com/kotelnik/plasma-applet-weather-widget
    cd ${HOME}/plasma-applet-weather-widget
    mkdir build
    cd build
    cmake .. \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DLIB_INSTALL_DIR=lib \
        -DKDE_INSTALL_USE_QT_SYS_PATHS=ON
    make
    sudo make install

    # Configure KDE and weather plasmoids
    file1=${HOME}/.config/plasma-org.kde.plasma.desktop-appletsrc
    file2=${HOME}/.config/plasma_calendar_holiday_regions

    sed -i 's/plugin=org.kde.plasma.digitalclock/plugin=org.kde.plasma.eventcalendar/g' $file1
    sed -i 's/AppletOrder=34;4;5;6;7;18;19/AppletOrder=34;4;5;6;44;7;18;19/g' $file1

    echo "[Containments][2][Applets][18][Configuration][General]
    clockShowLine2=true
    timerSfxFilepath=file:///usr/share/sounds/freedesktop/stereo/audio-channel-front-right.oga
    v71Migration=true
    v72Migration=true

    [Containments][2][Applets][18][Configuration][Google Calendar]
    calendarList=W10=
    tasklistList=W10=

    [Containments][2][Applets][18][Configuration][Weather]
    openWeatherMapCityId=$openWeatherMapCityId
    weatherUnits=imperial

    [Containments][2][Applets][44]
    immutability=1
    plugin=org.kde.weatherWidget

    [Containments][2][Applets][44][Configuration]
    PreloadWeight=75

    [Containments][2][Applets][44][Configuration][Appearance]
    inTrayActiveTimeoutSec=8000
    renderMeteogram=true

    [Containments][2][Applets][44][Configuration][ConfigDialog]
    DialogHeight=540
    DialogWidth=720

    [Containments][2][Applets][44][Configuration][General]
    lastReloadedMsJson={\"cache_5a5440a6c6026f3e61c6aee598cae8dc\":1637347842409,\"cache_3c6fc338a6d3824bb170a9f9e7628698\":1637348083971}
    places=[{\"providerId\":\"owm\",\"placeIdentifier\":\"$openWeatherMapCityId\",\"placeAlias\":\"$openWeatherMapCityAlias\"}]
    reloadIntervalMin=20

    [Containments][2][Applets][44][Configuration][Units]
    pressureType=inHg
    temperatureType=fahrenheit
    windSpeedType=mph" >> $file1

    echo "[General]
    selectedRegions=us_en-us" >> $file2
else
    echo "no weather configured"
fi

# In case someone installs syncthing
username=$(whoami)
systemctl enable syncthing@$username.service

echo "ready for 'arch-chroot /mnt /root/ArchTitus/3-post-setup.sh'"
