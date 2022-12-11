#!/bin/bash

# Código creado por rxfatalslash
# Instalación de Arch Linux automatizada

# Variable de lenguaje
clear
idioma=$(curl https://ipapi.co/languages | awk -F ";" '{print $1}' | sed 's/-/_/g' | sed "s|$|.UTF8|")
echo ""
echo "$idioma UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$idioma" > /etc/locale.conf
exportlang=$(echo "LANG=$idioma")
export $exportlang
export LANG=$idioma
export $(cat /etc/locale.conf)
locale-gen
echo ""
clear

# Disco
discosdisponibles=$(echo "print devices" | parted | grep /dev | awk '{if (NR!=1) {print}}' | sed '/sr/d')
clear
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
echo ""
echo "Rutas de disco disponibles: "
echo ""
echo "$discosdisponibles"
echo ""
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _

# Datos de usuario
echo ""
read -p "Introduce el disco de instalación: " disco
echo ""
read -p "Introduce nombre de nuevo usuario: " user
echo ""
read -p "Introduce la contraseña para $user: " userpasswd
echo ""
read -p "Introduce la contraseña para root: " rootpasswd
echo ""

# Escritorios
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
echo ""
echo "1. Terminal Virtual (TTY)"
echo ""
echo "2. Kde Plasma"
echo ""
echo "3. Gnome"
echo ""
read -p "Elije una opción de escritorio [1-3]: " escritorio
echo ""

# Aceptar instalación
echo ""
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
echo ""
echo ""
echo "Para confirmar e instalar Arch Linux"
echo ""
echo "Presione ENTER o CTRL + C para cancelar"
read line

# Detecta si nuestro sistema es UEFI o BIOS
uefi=$( ls /sys/firmware/efi/ | grep -ic efivars )

if [ uefi == 1 ]
then
    clear
    printf '%*s\n' "${COLUMNS:-(tput cols)}" '' | tr ' ' _
    echo ""
    echo "Tu sistema es UEFI"
    echo ""
    date "+%F %H:%M"
    sleep 3

    swapsize=$(free --giga | awk '/^Mem:/{print $2}')
    (echo Ignore) | sgdisk --zap-all ${disco}
    (echo 2; echo w; echo Y) | gdisk ${disco}
    sgdisk ${disco} -n=1:0:+100M -t=1:ef00
    sgdisk ${disco} -n=2:0:+${swapsize}G -t=2:8200
    sgdisk ${disco} -n=3:0:0
    fdisk -l ${disco} > /tmp/partition
    echo ""
    cat /tmp/partition
    sleep 3

    partition="$(cat /tmp/partition | grep /dev/ | awk '{if (NR!=1) {print}}' | sed 's/*//g' | awk -F ' ' '{print $1}')"
    echo $partition | awk -F ' ' '{print $1}' > boot-efi
    echo $partition | awk -F ' ' '{print $2}' > swap-efi
    echo $partition | awk -F ' ' '{print $3}' > root-efi

    clear
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    echo "Partición EFI es:"
    cat boot-efi
    echo ""
    echo "Partición SWAP es:"
    cat swap-efi
    echo ""
    echo "Partición ROOT es:"
    cat root-efi
    sleep 3

    clear
    echo ""
    echo "Formateando particiones"
    echo ""
    mkfs.ext4 $(cat root-efi)
    mount $(cat root-efi) /mnt

    mkdir -p /mnt/efi
    mkfs.fat -F 32 $(cat boot-efi)
    mount $(cat boot-efi) /mnt/efi

    mkswap $(cat swap-efi)
    swapon $(cat swap-efi)

    rm boot-efi
    rm swap-efi
    rm root-efi

    clear
    echo ""
    echo "Revise el punto de montaje en MOUNTPOINT - PRESIONE ENTER"
    echo ""
    lsblk -l
    read line
else
    clear
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    echo "Tu sistema es BIOS"
    echo ""
    date "+%F %H:%M"
    sleep 3

    read -p "¿Cuánto va a ocupar la partición raíz?: " raiz
    swapsize=$(free --giga | awk '/^Mem:/{print $2}')
    sgdisk --zap-all ${disco}
    (echo o; echo n; echo p; echo ""; echo ""; echo +512M; echo n; echo p; echo ""; echo ""; echo ${raiz}; echo n; echo p; echo ""; echo ""; echo ${swapsize}; echo t; echo 3; echo 82; echo a; echo 1; echo w; echo q;) | fdisk ${disco}

    mkfs.vfat -F 32 /dev/sda1
    mkfs.ext4 /dev/sda2
    mkswap /dev/sda3
    swapon

    mount /dev/sda2 /mnt
    mkdir /mnt/boot
    mount /dev/sda1 /mnt/boot
fi
clear
pacman -Syy
pacman -Sy archlinux-keyring --noconfirm
clear
pacstrap /mnt linux linux-firmware grub networkmanager wpa_supplicant base base-devel

genfstab -U /mnt
genfstab -U /mnt > /mnt/etc/fstab

arch-chroot /mnt /bin/bash -c "(echo $rootpasswd; echo $rootpasswd) | passwd root"
arch-chroot /mnt /bin/bash -c "useradd -m -s /bin/bash $user"
arch-chroot /mnt /bin/bash -c "(echo $userpasswd; echo $userpasswd) | passwd $user"
echo "$user ALL=(ALL:ALL) ALL" >> /mnt/etc/sudoers
clear

arch-chroot /mnt /bin/bash -c "pacman -S sudo vim nano --noconfirm"

# Idioma del sistema
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
echo -e ""
echo -e "\t\t\t| Idioma del sistema |"
echo -e ""
echo "$idioma UTF-8" > /mnt/etc/locale.gen
arch-chroot /mnt /bin/bash -c "locale-gen"
echo "LANG=$idioma" > /mnt/etc/locale.conf
echo ""
cat /mnt/etc/locale.conf
echo ""
cat /mnt/etc/locale.gen
sleep 4
echo ""
arch-chroot /mnt /bin/bash -c "sudo -u $user export $(cat /etc/locale.conf)"
export $(cat /mnt/etc/locale.conf)
arch-chroot /mnt /bin/bash -c "sudo -u $user export $(cat /etc/locale.conf)"
export $(cat /etc/locale.conf)
export $(cat /mnt/etc/locale.conf)
exportlang=$(echo "LANG=$idioma")
export $exportlang
export LANG=$idioma
locale-gen
arch-chroot /mnt /bin/bash -c "locale-gen"
clear
sleep 3

# Zona horaria automática
arch-chroot /mnt /bin/bash -c "pacman -Sy curl --noconfirm"
curl https://ipapi.co/timezone > zonahoraria
zonahoraria=$(cat zonahoraria)
arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/$zonahoraria /etc/localtime"
arch-chroot /mnt /bin/bash -c "timedatectl set-timezone $zonahoraria"
arch-chroot /mnt /bin/bash -c "pacman -S ntp --noconfirm"
arch-chroot /mnt /bin/bash -c "ntpd -qg"
arch-chroot /mnt /bin/bash -c "hwclock --systohc"
sleep 3
rm zonahoraria
clear

# Establecer un mapa de teclado para la terminal virtual
curl https://ipapi.co/languages | awk -F "," '{print $1}' | sed -e's/.$//' | sed -e's/.$//' | sed -e's/.$//' > keymap
keymap=$(cat keymap)
echo "KEYMAP=$keymap" > /mnt/etc/vconsole.conf
cat /mnt/etc/vconsole.conf
clear

# Actualiza lista de mirrors en tu disco
echo ""
echo "Actualizando lista de mirrorlist"
echo ""
arch-chroot /mnt /bin/bash -c "reflector --verbose --latest 15 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist"
clear
cat /mnt/etc/pacman.d/mirrorlist
sleep 3
clear

# Instalación de GRUB
arch-chroot /mnt /bin/bash -c "grub-install /dev/sda"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

# Hostname
read -p "Nombre de la máquina: " hostname
echo $hostname > /mnt/etc/hostname
echo "127.0.0.1 localhost" >> /mnt/etc/hosts
echo "::1       localhost" >> /mnt/etc/hosts
echo "127.0.0.1 $hostname.localhost $hostname" >> /mnt/etc/hosts

arch-chroot /mnt /bin/bash -c "pacman -S neofetch --noconfirm"
sleep 4

# Drivers de video
if (lspci | grep VGA | grep "NVIDIA\|nVidia" &>/dev/null); then
# Nvidia
arch-chroot /mnt /bin/bash -c "pacman -S xf86-video-nouveau mesa lib32-mesa mesa-vdpau libva-mesa-driver lib32-mesa-vdpau lib32-libva-mesa-driver libva-vdpau-driver libvdpau-va-gl libva-utils vdpauinfo libvdpau lib32-libvdpau opencl-mesa clinfo ocl-icd lib32-ocl-icd opencl-headers --noconfirm"

elif (lspci | grep VGA | grep "Radeon R\|R2/R3/R4/R5" &>/dev/null); then
# Radeon  
arch-chroot /mnt /bin/bash -c "pacman -S xf86-video-amdgpu mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon mesa-vdpau libva-mesa-driver lib32-mesa-vdpau lib32-libva-mesa-driver libva-vdpau-driver libvdpau-va-gl libva-utils vdpauinfo opencl-mesa clinfo ocl-icd lib32-ocl-icd opencl-headers --noconfirm"

elif (lspci | grep VGA | grep "ATI\|AMD/ATI" &>/dev/null); then
# ATI             
arch-chroot /mnt /bin/bash -c "pacman -S xf86-video-ati mesa lib32-mesa mesa-vdpau libva-mesa-driver lib32-mesa-vdpau lib32-libva-mesa-driver libva-vdpau-driver libvdpau-va-gl libva-utils vdpauinfo opencl-mesa clinfo ocl-icd lib32-ocl-icd opencl-headers --noconfirm"

elif (lspci | grep VGA | grep "Intel" &>/dev/null); then
# Intel       
arch-chroot /mnt /bin/bash -c "pacman -S xf86-video-intel vulkan-intel mesa lib32-mesa intel-media-driver libva-intel-driver libva-vdpau-driver libvdpau-va-gl libva-utils vdpauinfo intel-compute-runtime beignet clinfo ocl-icd lib32-ocl-icd opencl-headers --noconfirm"
    
else
# Generico   
arch-chroot /mnt /bin/bash -c "pacman -S xf86-video-vesa xf86-video-fbdev mesa mesa-libgl lib32-mesa --noconfirm"

fi
clear

# Instalación escritorio
case $escritorio in
    1)
        echo "Escritorio: Terminal Virtual (TTY)"
        sleep 3
        clear
    ;;

    2)
        echo "Escritoio: Kde Plasma"
        sleep 3

        # Instala Xorg
        arch-chroot /mnt /bin/bash -c "pacman -S xorg xorg-apps xorg-xinit xorg-twm xterm xorg-xclock --noconfirm"

        # Programas para KDE Plasma minimalista
        arch-chroot /mnt /bin/bash -c "pacman -S plasma dolphin konsole discover sddm ffmpegthumbs ffmpegthumbnailer --noconfirm"
        arch-chroot /mnt /bin/bash -c "systemctl enable sddm"

            # Establecer formato de teclado dentro de xorg
            keymap=es

            touch /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
            echo -e 'Section "InputClass"' > /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
            echo -e 'Identifier "system-keyboard"' >> /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
            echo -e 'MatchIsKeyboard "on"' >> /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
            echo -e 'Option "XkbLayout" "latam"' >> /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
            echo -e 'EndSection' >> /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
            echo ""
            cat /mnt/etc/X11/xorg.conf.d/00-keyboard.conf
            sleep 5
            clear

            # Audio
            arch-chroot /mnt /bin/bash -c "pacman -S pulseaudio pavucontrol --noconfirm"

            # Navegador web
            arch-chroot /mnt /bin/bash -c "pacman -S gnu-free-fonts ttf-hack ttf-inconsolata gnome-font-viewer --noconfirm"
    ;;

    3)
        echo "Escritorio: Gnome"
        sleep 3

        # Instala Xorg
        arch-chroot /mnt /bin/bash -c "pacman -S xorg xorg-server --noconfirm"

        # Programas para Gnome minimalista
        arch-chroot /mnt /bin/bash -c "pacman -S gnome --noconfirm"
        arch-chroot /mnt /bin/bash -c "systemctl enable gdm"
    ;;

    *)
        arch-chroot /mnt /bin/bash -c "pacman -Syu --noconfirm"
        clear
    ;;
esac

# Servicios
arch-chroot /mnt /bin/bash -c "systemctl enable NetworkManager"
arch-chroot /mnt /bin/bash -c "systemctl enable wpa_supplicant"
arch-chroot /mnt /bin/bash -c "systemctl enable gdm"

# Reinicio del sistema
clear
echo ""
echo "Se va a reiniciar el sistema"
sleep 5
reboot now