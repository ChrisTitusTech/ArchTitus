#!/bin/bash
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Read config file, error if it exists
#configFileName=${HOME}/ArchTitus/install.conf
configFileName=$SCRIPT_DIR/install.conf
if [ -e "$configFileName" ]; then
	echo "Configuration file install.conf already exists...  Cannot continue."
    exit
fi



echo -e "-------------------------------------------------------------------------"
echo -e "   █████╗ ██████╗  ██████╗██╗  ██╗████████╗██╗████████╗██╗   ██╗███████╗"
echo -e "  ██╔══██╗██╔══██╗██╔════╝██║  ██║╚══██╔══╝██║╚══██╔══╝██║   ██║██╔════╝"
echo -e "  ███████║██████╔╝██║     ███████║   ██║   ██║   ██║   ██║   ██║███████╗"
echo -e "  ██╔══██║██╔══██╗██║     ██╔══██║   ██║   ██║   ██║   ██║   ██║╚════██║"
echo -e "  ██║  ██║██║  ██║╚██████╗██║  ██║   ██║   ██║   ██║   ╚██████╔╝███████║"
echo -e "  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝   ╚═╝   ╚═╝   ╚═╝    ╚═════╝ ╚══════╝"




    echo -e "-------------------------------------------------------------------------"
    echo -e " This script will make a sample config file (install.conf) you can edit  "
    echo -e " It will ask for disk to format, username, password, and host as well as "
    echo -e " provide default package list for Arch and ARU you can modify.           "
    echo -e "-------------------------------------------------------------------------"
    echo ""
    lsblk
    echo ""
    echo "Above drive breakdown is from THIS MACHINE you are running this make config "
    echo "script on and MIGHT NOT BE THE SAME AS THE MACHINE YOU INTEND TO INSTALL TO "
    echo "Be Careful!"
    echo ""
    echo "Please enter disk to format: (example /dev/sda)"
    read disk
    disk="${disk,,}"
    if [[ "${disk}" != *"/dev/"* ]]; then
        disk="/dev/${disk}"
    fi
    echo "disk=$disk" >> $configFileName




# Get username
if [ -e "$configFileName" ] && [ ! -z "$username" ]; then
	echo "Creating user - $username."
else
	read -p "Please enter username:" username
	echo "username=$username" >> $configFileName
fi




#    if [ "$password" == "*!*CHANGEME*!*...and-dont-store-in-plantext..." ]; then
        while true; do
            read -s -p "Password for $username: " password
            echo
            read -s -p "Password for $username (again): " password2
            echo
	    if [ "$password" = "$password2" ] && [ "$password" != "" ]; then
	    	break
	    fi
	    echo "Please try again"
	done
#	sed -i.bak "s/^\(password=\).*/\1$password/" $configFileName
    echo "password=$password" >> $configFileName




# Set hostname
if [ -e "$configFileName" ] && [ ! -z "$hostname" ]; then
	echo "hostname: $hostname"
else
	read -p "Please name your machine:" hostname
	echo "hostname=$hostname" >> $configFileName
fi
#echo $hostname > /etc/hostname



echo "" >> $configFileName
echo "# Configuring this section enables showing weather on the taskbar" >> $configFileName
echo "# and forecasts on the calendar" >> $configFileName
echo "# Go to 'https://openweathermap.org/find' to get your City ID and Alias" >> $configFileName
echo "# This example is for Chicago." >> $configFileName
echo "#openWeatherMapCityId=4887398" >> $configFileName
echo "#openWeatherMapCityAlias=\"Chicago, US\"" >> $configFileName




# Read default packages from scrips into array...
# This section of code is not lifted from any other scrips in this repo...custom for this need.
PKGS_ARCH_DEFAULT=()
bolReadLine=false
while IFS= read -r line; do
    if [ "$line" == "PKGS_ARCH_DEFAULT=(" ]; then
        bolReadLine=true
    fi
    if [ "$line" == ")" ]; then
        bolReadLine=false
    fi
    if [ $bolReadLine == true ]; then
        PKGS_ARCH_DEFAULT+=("$line")
    fi
done < 1-setup.sh

PKGS_AUR_DEFAULT=()
bolReadLine=false
while IFS= read -r line; do
    if [ "$line" == "PKGS_AUR_DEFAULT=(" ]; then
        bolReadLine=true
    fi
    if [ "$line" == ")" ]; then
        bolReadLine=false
    fi
    if [ $bolReadLine == true ]; then
        PKGS_AUR_DEFAULT+=("$line")
    fi
done < 2-user.sh




echo "" >> $configFileName




## install default or user specified packages (if they exist)
#if [ ${#PKGS_AUR[@]} -eq 0 ]; then
#	echo "installing AUR default packages"
	for PKG in "${PKGS_AUR_DEFAULT[@]}"; do
#	    echo "INSTALLING AUR DEFAULT PACKAGE: ${PKG}"
#		yay -S --noconfirm $PKG
#	    echo "${PKG}"
	if [ "${PKG}" == "PKGS_AUR_DEFAULT=(" ]; then
		echo "PKGS_AUR=(" >> $configFileName
	else
        	echo "${PKG}" >> $configFileName
	fi
	done
#else
#	echo "installing AUR user specified packages"
#	for PKG in "${PKGS_AUR[@]}"; do
#	    echo "INSTALLING AUR USER SPECIFIED PACKAGE: ${PKG}"
#		yay -S --noconfirm $PKG
#	done
#fi




echo ")" >> $configFileName
echo "" >> $configFileName




## install default or user specified packages (if they exist)
#if [ ${#PKGS_ARCH[@]} -eq 0 ]; then
#	echo "installing arch default packages"
	for PKG in "${PKGS_ARCH_DEFAULT[@]}"; do
#	    echo "INSTALLING ARCH DEFAULT PACKAGE: ${PKG}"
#	    pacman -S "$PKG" --noconfirm --needed
        if [ "${PKG}" == "PKGS_ARCH_DEFAULT=(" ]; then
		echo "PKGS_ARCH=(" >> $configFileName
	else
        	echo "${PKG}" >> $configFileName
	fi
	done
#else
#	echo "installing arch user specified packages"
#	for PKG in "${PKGS_ARCH[@]}"; do
#	    echo "INSTALLING ARCH USER SPECIFIED PACKAGE: ${PKG}"
#	    pacman -S "$PKG" --noconfirm --needed
#	done
#fi



echo ")" >> $configFileName



echo "-------------------------------------------------------------------------"
echo "--              install.conf for $username generated"
echo "-------------------------------------------------------------------------"
