# ArchHodag Installer Script (Base)

This README contains the steps I do to install and configure a fully-functional Arch Linux installation containing a desktop environment, all the support packages (network, bluetooth, audio, printers, etc.), along with all my preferred applications and utilities. The shell scripts in this repo allow the entire process to be automated.)

---
## Create Arch ISO or Use Image

Download ArchISO from <https://archlinux.org/download/> and put on a USB drive with Ventoy or Etcher

## Boot Arch ISO

From initial Prompt type the following commands:

```
pacman -Sy git
git clone https://github.com/w9hdg/ArchHodag
cd ArchHodag
./archhodag.sh
```

### System Description
This is completely automated arch install of the KDE desktop environment on arch using all the packages I use on a daily basis. 

## Troubleshooting

__[Arch Linux Installation Guide](https://github.com/rickellis/Arch-Linux-Install-Guide)__

### No Wifi

```bash
sudo wifi-menu
```

## Credits

- Original script written by Chris Titus. The original can be located here: https://github.com/ChrisTitusTech/ArchTitus
- Original packages script was a post install cleanup script called ArchMatic located here: https://github.com/rickellis/ArchMatic
- Thank you to all the folks that helped during the creation from YouTube Chat! Here are all those Livestreams showing the creation: <https://www.youtube.com/watch?v=IkMCtkDIhe8&list=PLc7fktTRMBowNaBTsDHlL6X3P3ViX3tYg>
