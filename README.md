# BetterArch Installer Script


This README contains the steps I do to install and configure a fully-functional Arch Linux installation containing a desktop environment, all the support packages (network, bluetooth, audio, printers, etc.), along with all my preferred applications and utilities. The shell scripts in this repo allow the entire process to be automated.)

## Hardened Arch Linux

- Linux-Hardened kernel
- Linux-Hardened headers
- Fail2ban
- ProtonVPN
- Fail2ban
- UFW
- Portsmaster
- Firejail sandboxing


_Comes preinstalled with pentesting tools_

---
## Create Arch ISO or Use Image

Download ArchISO from <https://archlinux.org/download/> and put on a USB drive with Ventoy or Etcher


## Boot Arch ISO

From initial Prompt type the following commands:

```
pacman -Sy git
git clone https://github.com/71Zombie/BetterArch
cd BetterArch
./BetterArch.sh
```

## Troubleshooting

__[Arch Linux Installation Guide](https://github.com/rickellis/Arch-Linux-Install-Guide)__

