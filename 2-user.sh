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
'autojump' # A faster way to navigate your filesystem from the command line
'dxvk-bin' # DXVK DirectX to Vulcan
'github-desktop-bin' # Github Desktop sync
'icaclient' # Citrix Workspace App (a.k.a. ICAClient, Citrix Receiver) - Required for work
'mangohud' # Gaming FPS Counter
'mangohud-common' # Common files for mangohud and lib32-mangohud
'nerd-fonts-fira-code' # It's literally a heap of fonts
'nordic-darker-standard-buttons-theme' # Theme
'nordic-darker-theme' # Theme
'nordic-kde-git' # Theme
'nordic-theme' # Theme
'noto-fonts-emoji' # Theme
'papirus-icon-theme' # Theme
'plasma-pa' # Plasma applet for audio volume management using PulseAudio
'ocs-url' # install packages from websites
'sddm-nordic-theme-git' # Theme
'snap-pac' # Pacman hooks that use snapper to create pre/post btrfs snapshots like openSUSE's YaST
'snapper-gui-git' # Gui for snapper, a tool of managing snapshots of Btrfs subvolumes and LVM volumes
'spotify' #It's spotify bro you know what this is
'ttf-droid' # General-purpose fonts released by Google as part of Android
'ttf-hack' # A hand groomed and optically balanced typeface based on Bitstream Vera Mono.
'ttf-meslo' # Nerdfont package
'ttf-roboto' # Google's signature family of fonts
'zoom' # video conferences
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

echo -e "\nDone!\n"
exit
