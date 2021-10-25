#!/usr/bin/env bash
#------------------------------------------------------------------------------------
#                                                                          ▄▄
#▀███▀▀▀██▄         ██    ██                        ██                    ███
#  ██    ██         ██    ██                       ▄██▄                    ██
#  ██    ██ ▄▄█▀██████████████  ▄▄█▀██▀███▄███    ▄█▀██▄   ▀███▄███ ▄██▀██ ███████▄
#  ██▀▀▀█▄▄▄█▀   ██ ██    ██   ▄█▀   ██ ██▀ ▀▀   ▄█  ▀██     ██▀ ▀▀██▀  ██ ██    ██
#  ██    ▀███▀▀▀▀▀▀ ██    ██   ██▀▀▀▀▀▀ ██       ████████    ██    ██      ██    ██
#  ██    ▄███▄    ▄ ██    ██   ██▄    ▄ ██      █▀      ██   ██    ██▄    ▄██    ██
#▄████████  ▀█████▀ ▀████ ▀████ ▀█████▀████▄  ▄███▄   ▄████▄████▄   █████▀████  ████▄
#
#------------------------------------------------------------------------------------

echo -e "\nFINAL SETUP AND CONFIGURATION"

echo -e "\nInstalling penetration testing tools"

PKGS=(
'airgeddon-git' # Audit wireless networks
'ba-pentest-commons-meta'
'bettercap' # Netorking swiss army knife
'metasploit' # Exploit
'nmap' # Network scanning
'sherlock-git'
)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    sudo pacman -S "$PKG" --noconfirm --needed
done

cd ~/git
echo -e "\nInstalling git repositories\n"
git clone https://github.com/six2dez/reconftw.git
cd reconftw/
./install.sh

cd ~/git
git clone https://github.com/codingo/Reconnoitre.git
python3 setup.py install

cd ~/git
git clone https://github.com/AlisamTechnology/ATSCAN
chmod +x ./install.sh
./install.sh

cd ~/git
git clone https://github.com/evyatarmeged/Raccoon.git
cd Raccoon
python setup.py install # Subsequent changes to the source code will not be reflected in calls to raccoon when this is used




echo "
###############################################################################
# Done - Please Eject Install Media and Reboot
###############################################################################
"