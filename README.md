<div align="center">
    <img src="https://i.imgur.com/ux2gsDY.png" width="200px">

### 💻 Archinstall 💻

This is an automated script for the installation of Arch Linux, and there is a wide range of options to choose from during the system installation.
</div>

# Index
* ### [🗳️ Installation](#🗳️-installation)
* ### [🖱️ Use](#🖱️-use)
* ### [📋 License](#📋-license)

# 🗳️ Installation
First, the system is booted from the Arch Linux ISO image, and once inside the system, you should load the keyboard configuration corresponding to your region*.
```
loadkeys <region>
pacman -Syy
pacman -Sy archlinux-keyring --noconfirm
```
If you encounter a PGP signature error, execute the following commands
```
pacman-key --init
pacman-key --populate archlinux
```
If the problem persists, restart the system and try again to install the necessary packages.

# 🖱️ Use
Download and execute the script.
```
curl -O https://raw.githubusercontent.com/rxfatalslash/archinstall/refs/heads/main/archinstall.sh
chmod +x archinstall.sh
./archinstall.sh
```

# 📋 License
This project is licensed under the terms of the [GNU General Public License, version 3](https://www.gnu.org/licenses/gpl-3.0.html) (GPLv3).

## LICENSE SUMMARY
### Permissions:

* **FREEDOM TO USE:** You are free to use, modify, and distribute this software.

* **SOURCE CODE ACCESS:** You must provide access to the source code of any modified versions of the software under the same GPLv3 license.

### Conditions:

* **COPYLEFT:** Any derivative work must also be open-source and distributed under the GPLv3 license.

* **NOTICES:** When distributing the software, you must include a copy of the GPLv3 license and provide appropriate notices.

### Limitations:

* **NO WARRANTY:** The software is provided as-is with no warranties or guarantees.

* **LIABILITY:** The authors or copyright holders are not liable for any damages or issues arising from the use of the software.

<a href="https://www.gnu.org/licenses/gpl-3.0.html" target="_blank">
  <img src="https://upload.wikimedia.org/wikipedia/commons/9/93/GPLv3_Logo.svg" width="80" height="15" />
</a>