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

echo -e "\nFINAL SETUP AND CONFIGURATION\n"

ehco -e"\nInstalling black arch repository\n"

#mkdir $HOME/blackarch
#cp /root/BetterArch/dotfiles/blackarch/strap.sh $HOME/blackarch
#cd $HOME/blackarch
#chmod +x strap.sh
#sudo pacman -Syu

mkdir blackman
cd blackman
wget https://raw.github.com/BlackArch/blackarch/master/packages/blackman/PKGBUILD
makepkg -s


PKGS=(
'3proxy'
'a2sv'
'airgeddon-git' # Audit wireless networks
'autosploit'
'backdoor-factory'
'ba-pentest-commons-meta'
'bettercap' # Networking swiss army knife
'blue-hydra'
'firefox-security-toolkit'
#----------------#
'gitgraber'
'githack'
'github-dorks'
'githubcloner'
'gitleaks'
'gitmails'
'gitminer'
'gitrecon'
'gitrob'
'gittools'
#----------------#

'metasploit' # Exploit
'nmap' # Network scanning
'sherlock-git'
'sploitctl'
'torctl'
'wireshark-qt'
)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    sudo blackman -i "$PKG"
done


echo -e "\nInstalling git repositories\n"
mkdir $HOME/git
cd $HOME/git
git clone https://github.com/six2dez/reconftw.git
cd reconftw/
./install.sh

cd $HOME/git
git clone https://github.com/codingo/Reconnoitre.git
python3 setup.py install

cd $HOME/git
git clone https://github.com/AlisamTechnology/ATSCAN
chmod +x ./install.sh
./install.sh

cd $HOME/git
git clone https://github.com/evyatarmeged/Raccoon.git
cd Raccoon
python setup.py install # Subsequent changes to the source code will not be reflected in calls to raccoon when this is used

cd $HOME/git
git clone https://github.com/haad/proxychains
cd proxychains
./configure
make
sudo make install

cd ~


echo "
###############################################################################
# Cleaning
###############################################################################
"
# Remove no password sudo rights
sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
# Add sudo rights
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Replace in the same state
cd $pwd

top -b -n 1 | head | grep -A 1 PID | grep "^[0-9]" | cut -f1 -d" " | xargs kill

echo "
###############################################################################
# Done - Please Eject Install Media and Reboot
###############################################################################
"