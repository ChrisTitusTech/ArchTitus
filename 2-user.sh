#!/usr/bin/env bash

# You can solve users running this script as root
# with this and then doing the same for the next for statement.
# However I will leave this up to you.
# shellcheck disable=SC1091
# shellcheck source=./setup.conf
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

CONFIG_FILE="$SCRIPT_DIR"/setup.conf
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "ERROR! Missing file: setup.conf"
    exit 1
fi

cd ~ || exit 1
case "$AURHELPER" in
"yay")
    install_pkg "git go"
    git clone "https://aur.archlinux.org/yay.git"
    ;;
"trizen")
    install_pkg "git perl"
    git clone "https://aur.archlinux.org/trizen.git"
    ;;
"aurman")
    install_pkg "git"
    git clone "https://aur.archlinux.org/aurman.git"
    ;;
"aura")
    install_pkg "git stack"
    git clone "https://aur.archlinux.org/aura.git"
    ;;
"pikaur")
    install_pkg "git"
    git clone "https://aur.archlinux.org/pikaur.git"
    ;;
*)
    something_failed
    ;;
esac
cd "$AURHELPER" || exit 1
makepkg -si --noconfirm
cd ~ || exit 1


"$AURHELPER" -S --noconfirm --needed - <~/ArchTitus/pkg-files/aur-pkgs.txt

if [[ "$LAYOUT" -eq 1 ]]; then
    touch "$HOME/.cache/zshhistory"
    git clone "https://github.com/ChrisTitusTech/zsh"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
    ln -s "$HOME/zsh/.zshrc" ~/.zshrc
fi

export PATH=$PATH:~/.local/bin
cp -r ~/ArchTitus/dotfiles/* ~/.config/
pip install konsave
konsave -i ~/ArchTitus/kde.knsv
sleep 1
konsave -a kde

title "System ready for 3-post-setup.sh"
