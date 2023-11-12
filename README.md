This is an automated script for the installation of Arch Linux, and there is a wide range of options to choose from during the system installation.

# Installation
First, the system is booted from the Arch Linux ISO image, and once inside the system, you should load the keyboard configuration corresponding to your region with the command **loadkeys _zone_**. Then, install git to be able to clone the repository
```
loadkeys es
pacman -Syy
pacman -Sy archlinux-keyring --noconfirm
```
If you encounter a PGP signature error, execute the following commands
```
pacman-key --init
pacman-key --populate archlinux
```
If the problem persists, restart the system and try again to install the necessary packages.
<br><br>
Install git
```
pacman -Sy git --noconfirm
```
## Repository Cloning
Clone the repository, enter it, and run the installer. This is where the entire Arch Linux system installation process will begin
```
git clone https://github.com/rxfatalslash/archinstall
cd archinstall/
sh archinstall.sh
```
