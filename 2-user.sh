#!/usr/bin/env bash
#-------------------------------------------------------------------------
#   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗
#  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝
#  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗
#  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║
#  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║
#  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝
#-------------------------------------------------------------------------

echo -e "\nINSTALLING AUR SOFTWARE\n"
# You can solve users running this script as root with this and then doing the same for the next for statement. However I will leave this up to you.

echo "CLONING: YAY"
cd ~
git clone "https://aur.archlinux.org/yay.git"
cd ${HOME}/yay
makepkg -si --noconfirm
cd ~
touch "$HOME/.cache/zshhistory"
git clone "https://github.com/ChrisTitusTech/zsh"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $HOME/powerlevel10k
ln -s "$HOME/zsh/.zshrc" $HOME/.zshrc

PKGS=(
'autojump'
'awesome-terminal-fonts'
'brave-bin' # Brave Browser
'dxvk-bin' # DXVK DirectX to Vulcan
'firefox'
'github-desktop-bin' # Github Desktop sync
'lightly-git'
'mangohud' # Gaming FPS Counter
'mangohud-common'
'nerd-fonts-fira-code'
'nordic-darker-standard-buttons-theme'
'nordic-darker-theme'
'nordic-kde-git'
'nordic-theme'
'noto-fonts-emoji'
'papirus-icon-theme'
'ocs-url' # install packages from websites
'sddm-nordic-theme-git'
'snapper-gui-git'
'ttf-droid'
'ttf-hack'
'ttf-meslo' # Nerdfont package
'ttf-roboto'
'zoom' # video conferences
'snap-pac'
)

for PKG in "${PKGS[@]}"; do
    yay -S --noconfirm $PKG
done

export PATH=$PATH:~/.local/bin
cp -r $HOME/ArchTitus/dotfiles/* $HOME/.config/
pip install konsave
konsave -i $HOME/ArchTitus/kde.knsv
sleep 1
konsave -a kde

echo -e "\nInstalling PortsMaster\n"
sudo pacman -S libnetfilter_queue libappindicator-gtk3

git clone https://github.com/safing/portmaster-packaging
cd portmaster-packaging/linux
makepkg -is

#mkdir -p /var/lib/portmaster
#wget -O /tmp/portmaster-start https://updates.safing.io/latest/linux_amd64/start/portmaster-start
#sudo mv /tmp/portmaster-start /var/lib/portmaster/portmaster-start
#sudo chmod a+x /var/lib/portmaster/portmaster-start
#sudo /var/lib/portmaster/portmaster-start --data /var/lib/portmaster update
#sudo /var/lib/portmaster/portmaster-start core
#git clone https://github.com/safing/portmaster-packaging/ /tmp/portmaster-packaging
#sudo cp /tmp/portmaster-packaging/blob/master/linux/debian/portmaster.service /etc/systemd/system/
#sudo systemctl enable --now portmaster

echo -e "\nInstalling ProtonVPN\n"
sudo pacman -Syu libappindicator-gtk3 gnome-shell-extension-appindicator
sudo pamac update --force-refresh
pamac build protonvpn

echo -e "\nDone!\n"
exit
