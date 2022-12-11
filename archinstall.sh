#!/bin/bash
# Creador del código rxfatalslash

# Variable para lenguaje
clear
idioma=$(curl https://ipapi.co/languages | awk -F ";" '{print $1}' | sed 's/-/_/g' | sed "s|$|.UTF8|")
clear
echo ""
echo "$idioma UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$idioma" > /etc/locale.conf
exportlang = $(echo "LANG=$idioma")
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
echo "Rutas de Disco disponible: "
echo ""
echo $discosdisponibles
echo ""
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _

# Ingresar datos de usuario
echo ""
read -p "Introduce tu disco a instalar Arch: " disco
echo ""
read -p "Introduce Nombre usuario Nuevo: " user
echo ""
read -p "Introduce la clave de $user: " userpasswd
echo ""
read -p "Introduce la clave de root: " rootpasswd
echo ""

# Escritorios
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
echo ''
echo "Seleccion de Disco: $disco"
echo ''
echo "Tu usuario: $user"
echo ''
echo "Clave de usuario: $userpasswd"
echo ''
echo "Clave de root: $rootpasswd"
echo ''

# Opción elegida por usuario y realizamos la acción
case $escritorio in
    1)
        echo "Escritorio: Terminal Virtual (TTY)"
    ;;

    2)
        echo "Escritorio: Xfce4"
    ;;

    3)
        echo "Escritorio: Kde Plasma"
    ;;

    4)
        echo "Escritorio: Gnome"
    ;;
    *)
        echo "Incorrecto: Por defecto se instalará Gnome"
    ;;
esac
echo ""
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
echo ""
echo ""
echo "Para confirmar e instalar Arch Linux"
echo ""
echo "Presione ENTER o para salir presione CTRL + C"
read line

# DETECTA SI NUESTRO SISTEMA ES UEFI O BIOS LEGACY

uefi=$( ls /sys/firmware/efi/ | grep -ic efivars )

if [ $uefi == 1 ]
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
    print '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    echo "Tu sistema es BIOS"
    echo ""
    date "+%F %H:%M"
    sleep 3
    
    swapsize=$(free --giga | awk '/^Mem:/{print $2}')
    sgdisk --zap-all ${disco}
    (echo o; echo n; echo 1; echo ""; echo +100M; echo n; echo p; echo 2; echo ""; echo +${swapsize}G; echo n; echo p; echo 3; echo ""; echo ""; echo t; echo 2; echo 82; echo a; echo 1; echo w; echo q) | fdisk ${disco}
    fdisk -l ${disco} > /tmp/partition
    cat /tmp/partition
    sleep 3

    partition="$(cat /tmp/partition | grep /dev/ | awk '{if (NR!=1) {print}}' | sed 's/*//g' | awk -F ' ' '{print $1}')"
    
    echo $partition | awk -F ' ' '{print $1}' > boot-bios
    echo $partition | awk -F ' ' '{print $2}' > swap-bios
    echo $partition | awk -F ' ' '{print $3}' > root-bios

    clear
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    echo "Partición BOOT es:"
    cat swap-bios
    echo ""
    echo "Partición ROOT es:"
    cat root-bios
    sleep 3

    clear
    echo ""
    echo "Revise el punto de montaje el MOUNTPOINT"
    echo ""
    lsblk -l
    sleep 4
    clear
fi
clear
pacman -Syy
pacman -Sy archlinux-keyring --noconfirm
clear
pacman -Sy reflector python rsync glibc curl --noconfirm
sleep 3
clear
echo ""
echo "Actualizando lista de mirrorlist"
echo ""
reflector --verbose --latest 5 --protocol http --protocol https --sort rate --save /etc/pacman.d/mirrorlist
clear
cat /etc/pacman.d/mirrorlist
sleep 3
clear

# Instalando sistema base en nuestro disco
echo ""
echo "Instalando sistema base"
echo ""
pacstrap /mnt base base-devel nano reflector python rsync
clear

# Creando archivo FSTAB para detectar al iniciar el sistema
echo ""
echo "Archivo FSTAB"
echo ""
echo "genfstab -p /mnt >> /mnt/etc/fstab"
echo ""
genfstab -p /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
sleep 4
clear

# Configurando pacman para que tenga colores con el repo MultiLib
sed -i 's/#Color/Color/g' /mnt/etc/pacman.conf
sed -i 's/#TotalDownload/TotalDownload/g' /mnt/etc/pacman.conf
sed -i 's/#VerbosePkgLists/g' /mnt/etc/pacman.conf
sed -i "37i ILoveCandy" /mnt/etc/pacman.conf
sed -i 's/#[multilib]/[multilib]/g' /mnt/etc/pacman.conf
sed -i "s/#Include = /etc/pacman.d/mirrorlist/Include = /etc/pacman.d/mirrorlist/g" /mnt/etc/pacman.conf
clear

# Hosts y nombre de la máquina
clear
read -p "Introduce el nombre de la máquina: " hostname
echo "$hostname" > /mnt/etc/hostname
echo "127.0.0.1 $hostname.localhost $hostname" > /mnt/etc/Hosts
clear
echo "Hostname: $(cat /mnt/etc/hostname)"
echo ""
echo "Hosts: $(cat /mnt/etc/hosts)"
echo ""
clear

# Agregando usuario y claves con administrador
arch-chroot /mnt /bin/bash -c "(echo $rootpasswd ; echo $rootpasswd) | passwd root"
arch-chroot /mnt /bin/bash -c "useradd -m -g users -s /bin/bash $user"
arch-chroot /mnt /bin/bash -c "(echo $userpasswd ; echo $userpasswd) | passwd $user"
sed -i "80i $user ALL=(ALL) ALL" /mnt/etc/sudoers
clear

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

# Instalación del kernel estable
arch-chroot /mnt /bin/bash -c "pacman -S linux linux-firmware linux-headers mkinitcpio --noconfirm"
clear

# Instalación de GRUB
if [ $uefi == 1 ]
then

arch-chroot /mnt /bin/bash -c "pacman -S grub efibottmgr os-prober dosfstools --noconfirm"
echo ''
echo 'Instalando EFI System >> bootx64.efi'
arch-chroot /mnt /bin/bash -c 'grub-install --target=xf86_64-efi --efi-directory=/efi --removable'
echo ''
echo 'Instalando UEFI System >> grubx64.efi'
arch-chroot /mnt /bin/bash -c 'grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch'
######
sed -i "6iGRUB_CMDLINE_LINUX_DEFAULT="loglevel=3"" /mnt/etc/default/grub
sed -i '7d' /mnt/etc/default/grub
######
echo ''
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
echo 'ls -l /mnt/efi'
ls -l /mnt/efi
echo ''
echo 'Lea bien que no tenga ningún error marcado'
echo '> Confirme tener las IMG de linux para el arranque'
echo '> Confirme tener la carpeta de GRUB para el arranque'
sleep 4

else

clear
arch-chroot /mnt /bin/bash -c "pacman -S grub os-prober --noconfirm"
echo ''
arch-chroot /mnt /bin/bash -c "grub-install --target=i386-pc $disco"
######
sed -i "6iGRUB_CMDLINE_LINUX_DEFAULT="loglevel=3"" /mnt/etc/default/grub
sed -i '7d' /mnt/etc/default/grub
######
echo ''
echo 'ls -l /mnt/boot'
ls -l /mnt/boot
echo ''
echo 'Lea bien que no tenga ningún error marcado'
echo '> Confirme tener las IMG de linux para el arranque'
echo '> Confirme tener la carpeta de GRUB para el arranque'

fi

clear

# Ethernet
arch-chroot /mnt /bin/bash -c "pacman -S dchpcd networkmanager iwd net-tools ifplugd --noconfirm"
arch-chroot /mnt /bin/bash -c "systemctl enable dhcpcd NetworkManager"
echo "noipv6rs" >> /mnt/etc/dhcpcd.conf
echo "noipv6" >> /mnt/etc/dhcpcd.conf
clear

# Wifi
#arch-chroot /mnt /bin/bash -c "pacman -S iw wireless_tools wpa_supplicant dialog wireless-regdb --noconfirm"

# Shell del sistema
arch-chroot /mnt /bin/bash -c "pacman -S zsh zsh-completions zsh-syntax-highlighting zsh-autosuggestions --noconfirm"
SH=zsh
arch-chroot /mnt /bin/bash -c "chsh -s /bin/$SH"
arch-chroot /mnt /bin/bash -c "chsh -s /usr/bin/$SH $user"
arch-chroot /mnt /bin/bash -c "chsh -s /bin/$SH $user"
clear

# Directorios del sistema
arch-chroot /mnt /bin/bash -c "pacman -S git wget neofetch lsb-release xdg-user-dirs --noconfirm"
arch-chroot /mnt /bin/bash -c "xdg-user-dirs-update"
echo ""
arch-chroot /mnt /bin/bash -c "ls /home/$user"
sleep 5
clear

# Driver de video automático solo drivers libres
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

# Escritorio seleccionado
case $escritorio in
    1)
        echo "Escritorio: Terminal Virtual (TTY)"
        sleep 3
        clear
    ;;

    2)
        echo "Escritorio: Xfce4"
        sleep 3

        # Instala xorg
        arch-chroot /mnt /bin/bash -c "pacman -S xorg xorg-apps xorg-xinit xorg-twm xterm xorg-xclock --noconfirm"

        # Programas de Xfce4
        arch-chroot /mnt /bin/bash -c "pacman -S xfce4 xfce4-goodies network-manager-applet ffmpegthumbs ffmpegthumbnailer --noconfirm"
        
            # Programas para Login
            arch-chroot /mnt /bin/bash -c "pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings light-locker accountsservice --noconfirm"
            arch-chroot /mnt /bin/bash -c "systemctl enable lightdm"

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
            clear

            # Fonts
            arch-chroot /mnt /bin/bash -c "pacman -S gnu-free-fonts ttf-hack ttf-inconsolata gnome-font-viewer --noconfirm"
            clear

            # Navegador web
            arch-chroot /mnt /bin/bash -c "pacman -S firefox --noconfirm"
            clear
    ;;

    3)
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

    4)
        echo "Escritorio: Gnome"
        sleep 3

        # Instala Xorg
        arch-chroot /mnt /bin/bash -c "pacman -S xorg xorg-apps xorg-xinit xorg-twm xterm xorg-xclock --noconfirm"

        # Programas para Gnome minimalista
        arch-chroot /mnt /bin/bash -c "pacman -S gnome-shell gdm gnome-control-center gnome-tweaks gnome-terminal nautilus --noconfirm"
        arch-chroot /mnt /bin/bash -c "systemctl enable gdm"

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
            clear

            # Fonts
            arch-chroot /mnt /bin/bash -c "pacman -S gnu-free-fonts ttf-hack ttf-inconsolata gnome-font-viewer --noconfirm"
            clear


            # Navegador Web
            arch-chroot /mnt /bin/bash -c "pacman -S firefox --noconfirm"
            clear

    ;;

    *)
        arch-chroot /mnt /bin/bash -c "pacman -Syu --noconfirm"
        clear
    ;;
esac

#DESMONTAR Y REINICIAR
umount -R /mnt
swapoff -a
clear
echo ""
echo "Visita: https://t.me/ArchLinuxCristo"
echo ""
echo "Apóyame en Patreon: "
echo "https://www.patreon.com/codigocristo"
sleep 5
reboot
