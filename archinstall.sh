#!/bin/bash

# Autor: rxfatalslash
# Instalación de Arch Linux automatizada

# Variables de color
CRE=$(tput setaf 1)
CGR=$(tput setaf 2)
CYE=$(tput setaf 3)
CBL=$(tput setaf 4)
BLD=$(tput bold)
CNC=$(tput sgr0)

# Logo
logo () {

    local text="${1:?}"
    echo -en "
    WOdddddxk0KNW                                            WNK0kxdddddOW 
     Wo........',:lx0N                                    N0xl:,'........oW 
      Xc.,clcc:;'....;lON                              NOl;....';:cclc,.cX  
       Kc'cdodlc::ccc;..:kN                          Nk:..;ccc::cldodc'cK   
        Xo;:loooooooool:,'cK                        Kc',:loooooooool:;oX    
         WKxolccclllllllc;';OW                    WO;';clllllllcccloxKW     
            WNKOOOOkkkOkkkdokN                    NkodkkkOkkkOOOOKNW       
    \n\n"
    printf ' %s [%s%s %s%s %s]%s\n\n' "${CRE}" "${CNC}" "${CYE}" "${text}" "${CNC}" "${CRE}" "${CNC}"
}


# Variable de lenguaje
clear
idioma=$(echo "$(curl https://ipapi.co/languages | awk -F ";" '{print $1}' | sed "s|$|.UTF-8|") UTF-8")
pais=$(curl https://ipapi.co/country_tld | sed 's/^.//g')
clear

# Variable zona horaria
clear
timezone=$(curl https://ipapi.co/timezone)
clear

logo "rxfatalslash"

printf "%s%sEste script está automatizado para instalar Arch en tu PC de manera personalizable%s\n\n" "${BLD}" "${CRE}" "${CNC}"

# Confirmación
while true; do
    read -rp "¿Quieres continuar con la instalación [s/N]: " confirm
    case $confirm in
        [Ss]*) break;;
        [Nn]*) exit;;
        *) printf "%s%sError: Escribe solo 's' o 'n'%s\n\n" "${BLD}" "${CRE}" "${CNC}"
    esac
done

# Disco
discosdisponibles=$(echo "print devices" | parted | grep /dev | awk '{if (NR!=1) {print}}' | sed '/sr/d')
clear
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
echo ""
printf "%s%sRutas de disco disponibles:\n\n%s%s" "${BLD}" "${CBL}" "${discosdisponibles}" "${CNC}"
echo ""
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _

# Datos de usuario
echo ""
read -e -p "${BLD}${CBL}Introduce el disco de instalación:${CNC} " disco
clear
echo ""
read -e -p "${BLD}${CBL}Introduce nombre de nuevo usuario:${CNC} " user
echo ""
read -e -p "${BLD}${CBL}¿Quiéres que el nuevo usuario sea administrador [S/n]:${CNC} " adminask
case $adminask in
    [Nn]*) printf "%s%sEl usuario no será administrador%s" "${BLD}" "${CRE}" "${CNC}";;
    *) printf "%s%sEl usuario será administrador%s" "${BLD}" "${CGR}" "${CNC}";;
esac
echo ""
read -e -sp "${BLD}${CBL}Introduce la contraseña para $user:${CNC} " userpasswd
echo ""
read -e -sp "${BLD}${CBL}Introduce la contraseña para root:${CNC} " rootpasswd
echo ""
clear

# Aceptar instalación
echo ""
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
echo ""
echo ""
printf "%s%sPara confirmar e instalar Arch Linux\n\nPresione ENTER o CTRL + C para cancelar%s" "${BLD}" "${CBL}" "${CNC}"
read line

# Detecta si nuestro sistema es UEFI o BIOS
uefi=$( ls /sys/firmware/efi/ | grep -ic efivars )

if [ uefi == 1 ]; then
    clear
    printf '%*s\n' "${COLUMNS:-(tput cols)}" '' | tr ' ' _
    echo ""
    printf "%s%sTu sistema es UEFI%s\n" "${BLD}" "${CBL}" "${CNC}"
    date "+%F %H:%M"
    sleep 3

    calc=$(free --giga | awk '/^Mem/{print $2}')
    swapsize=$(expr $calc + 0)
    if [ $swapsize -le 4 ]; then
        swap=2
    elif [ $swapsize -gt 4 && $swapsize -le 16 ]; then
        swap=4
    elif [ $swapsize -gt 16 && $swapsize -le 64 ]; then
        swap=8
    fi

    (echo Ignore) | sgdisk --zap-all ${disco}
    (echo w; echo Y) | gdisk ${disco}
    sgdisk ${disco} -n=1:0:+512M -t=1:ef00
    sgdisk ${disco} -n=2:0:+${swap}G -t=2:8200
    sgdisk ${disco} -n=3:0:0
    fdisk -l ${disco} > /tmp/partition
    echo ""
    cat /tmp/partition
    sleep 3

    partition=$(cat /tmp/partition | grep "/dev/" | awk 'NR>1 {print}' | awk -F ' ' '{print $1}')
    echo $partition | tr ' ' ';' | cut -d ';' -f1 > boot-efi
    echo $partition | tr ' ' ';' | cut -d ';' -f2 > swap-efi
    echo $partition | tr ' ' ';' | cut -d ';' -f3 > root-efi

    clear
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    printf "%s%sPartición EFI es:%s" "${BLD}" "${CBL}" "${CNC}"
    cat boot-efi
    echo ""
    printf "%s%sPartición SWAP es:%s" "${BLD}" "${CBL}" "${CNC}"
    cat swap-efi
    echo ""
    printf "%s%sPartición ROOT es:%s" "${BLD}" "${CBL}" "${CNC}"
    cat root-efi
    sleep 3

    clear
    echo ""
    logo "Formateando particiones..."
    mkfs.ext4 $(cat root-efi)
    mount $(cat root-efi) /mnt

    mkfs.fat -F 32 $(cat boot-efi)
    mount --mkdir $(cat boot-efi) /mnt/efi

    mkswap $(cat swap-efi)
    swapon $(cat swap-efi)

    rm boot-efi
    rm swap-efi
    rm root-efi

    clear
    echo ""
    printf "%s%sRevise el punto de montaje en MOUNTPOINT - PRESIONE ENTER%s"  "${BLD}" "${CGR}" "${CNC}"
    echo ""
    lsblk -l
    read line
else
    clear
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    printf "%s%sTu sistema es BIOS%s\n" "${BLD}" "${CBL}" "${CNC}"
    date "+%F %H:%M"
    sleep 3

    calc=$(free --giga | awk '/^Mem/{print $2}')
    swapsize=$(expr $calc + 0)
    if [ $swapsize -le 4 ]; then
        swap=2
    elif [ $swapsize -gt 4 && $swapsize -le 16 ]; then
        swap=4
    elif [ $swapsize -gt 16 && $swapsize -le 64 ]; then
        swap=8
    fi

    (echo n; echo p; echo "1"; echo ""; echo "+512M"; echo n; echo p; echo "2"; echo ""; echo "+${swap}G"; echo t; echo "2"; echo "82"; echo n; echo p; echo "3"; echo ""; echo ""; echo t; echo "3"; echo "83"; echo w;) | fdisk ${disco}
    fdisk -l ${disco} > /tmp/partition
    echo ""
    cat /tmp/partition
    sleep 3

    partition=$(cat /tmp/partition | grep "/dev/" | awk 'NR>1 {print}' | awk -F ' ' '{print $1}')
    echo $partition | tr ' ' ';' | cut -d ';' -f1 > boot-part
    echo $partition | tr ' ' ';' | cut -d ';' -f2 > swap-part
    echo $partition | tr ' ' ';' | cut -d ';' -f3 > root-part

    clear
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    printf "%s%sPartición BOOT es:%s " "${BLD}" "${CBL}" "${CNC}"
    cat boot-part
    echo ""
    printf "%s%sPartición SWAP es:%s " "${BLD}" "${CBL}" "${CNC}"
    cat swap-part
    echo ""
    printf "%s%sPartición ROOT es:%s " "${BLD}" "${CBL}" "${CNC}"
    cat root-part
    sleep 3

    mkfs.ext4 $(cat root-part)
    mount $(cat root-part) /mnt

    mkfs.fat -F 32 $(cat boot-part)
    mkdir -p /mnt/boot
    mount $(cat boot-part) /mnt/boot

    mkswap $(cat swap-part)
    swapon $(cat swap-part)

    rm boot-part
    rm swap-part
    rm root-part

    clear
    echo ""
    printf "%s%sRevise el punto de montaje en MOUNTPOINT - PRESIONE ENTER%s\n" "${BLD}" "${CGR}" "${CNC}"
    lsblk -l
    read line
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
case $adminask in
    [Nn]*) continue;;
    *) echo "${user} ALL=(ALL:ALL) ALL" >> /mnt/etc/sudoers;;
esac
clear

arch-chroot /mnt /bin/bash -c "pacman -S sudo vim nano --noconfirm"

# Zona horaria del sistema
arch-chroot /mnt /bin/bash -c "ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime"
arch-chroot /mnt /bin/bash -c "hwclock --systohc"

# Idioma del sistema
clear
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
echo -e ""
logo "Configurando idioma del sistema..."
sleep 3
echo -e ""
echo $idioma >> /mnt/etc/locale.gen
arch-chroot /mnt /bin/bash -c "locale-gen"
echo "KEYMAP=${pais}" >> /mnt/etc/vconsole.conf
clear

# Instalación de GRUB
logo "Instalando grub..."
arch-chroot /mnt /bin/bash -c "grub-install /dev/sda"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"
sleep 3

# Hostname
clear
read -e -p "${BLD}${CBL}Nombre de la máquina:${CNC} " hostname
echo $hostname > /mnt/etc/hostname
echo "127.0.0.1 localhost" >> /mnt/etc/hosts
echo "::1       localhost" >> /mnt/etc/hosts
echo "127.0.0.1 $hostname.localhost $hostname" >> /mnt/etc/hosts
arch-chroot /mnt /bin/bash -c "pacman -S neofetch --noconfirm"
clear

logo "Instalando drivers de vídeo..."
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
sleep 3
clear

# Firefox
while true; do
    read -e -p "${BLD}${CBL}¿Quieres instalar Firefox? [s/N]:${CNC} " firefox
    clear

    case $firefox in
        [Ss]*)
            logo "Instalando Firefox..."
            sleep 3
            arch-chroot /mnt /bin/bash -c "pacman -S firefox --noconfirm"
            break
        ;;
        [Nn]*) break;;
        *) prinft "%s%sError: Escribe solo 's' o 'n'%s\n\n" "${CBL}" "${CRE}" "${CNC}"
    esac
done
clear

# Instalación escritorio
while true; do
    # Escritorios
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' _
    echo ""
    printf "%s%s1. Terminal Virtual (TTY)%s" "${BLD}" "${CBL}" "${CNC}"
    echo ""
    printf "%s%s2. Kde Plasma%s" "${BLD}" "${CBL}" "${CNC}"
    echo ""
    printf "%s%s3. Gnome%s" "${BLD}" "${CBL}" "${CNC}"
    echo ""
    printf "%s%s3. i3WM%s" "${BLD}" "${CBL}" "${CNC}"
    echo ""
    printf "%s%s------------------------------------%s" "${BLD}" "${CBL}" "${CNC}"
    echo ""
    read -e -p "${BLD}${CBL}Elije una opción de escritorio [1-4]:${CNC} " escritorio
    clear

    case $escritorio in
        1)
            logo "Configurando Terminal Virtual (TTY)..."
            sleep 3
            clear
            break
        ;;
        2)
            logo "Instalando Kde Plasma..."
            sleep 3

            # Instala Xorg
            arch-chroot /mnt /bin/bash -c "pacman -S xorg xorg-apps xorg-xinit xorg-twm xterm xorg-xclock --noconfirm"

            # Programas para KDE Plasma minimalista
            arch-chroot /mnt /bin/bash -c "pacman -S plasma dolphin konsole discover sddm ffmpegthumbs ffmpegthumbnailer --noconfirm"
            arch-chroot /mnt /bin/bash -c "systemctl enable sddm"

            # Establecer formato de teclado dentro de xorg
            keymap=$pais

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
            break
        ;;
        3)
            clear
            logo "Instalando Gnome..."
            sleep 3

            # Instala Xorg
            arch-chroot /mnt /bin/bash -c "pacman -S xorg xorg-server --noconfirm"

            # Programas para Gnome minimalista
            arch-chroot /mnt /bin/bash -c "pacman -S gnome --noconfirm"
            arch-chroot /mnt /bin/bash -c "systemctl enable gdm"
            break
        ;;
        4)
            clear
            logo "Instalando i3..."
            arch-chroot /mnt /bin/bash -c "sudo pacman -Syy i3-wm i3status i3lock dmenu termite dunst nitrogen"
            arch-chroot /mnt /bin/bash -c "echo 'exec i3' >> ~/.xinitrc"
        *) printf "%s%sError: Escribe un número 1-3%s\n\n" "${BLD}" "${CRE}" "${CNC}";;
    esac
done

pacman -Sy neofetch --noconfirm
host=$(neofetch | grep Host | sed 's/ //g' | cut -d ':' -f2)
if grep -q "VMware" <<< $host; then
    # VMWare Tools
    clear
    while true; do
        read -e -p "${BLD}${CBL}¿Quieres instalar las VMTools? [s/N]:${CNC} " vmtools
        clear

        case $vmtools in
            [Ss]*)
                # Paquetes para de VMWare Tools
                logo "Instalando VMTools..."
                sleep 3
                arch-chroot /mnt /bin/bash -c "pacman -Sy gtkmm --noconfirm"
                arch-chroot /mnt /bin/bash -c "pacman -Sy open-vm-tools --noconfirm"
                arch-chroot /mnt /bin/bash -c "pacman -Sy xf86-video-vmware xf86-input-vmmouse --noconfirm"

                # Servicios
                arch-chroot /mnt /bin/bash -c "systemctl enable vmtoolsd"
                break
            ;;
            [Nn]*) break;;
            *) printf "%s%sError: Escribe solo 's' o 'n'%s\n\n" "${BLD}" "${CRE}" "${CNC}";;
        esac
    done
elif grep -q "VirtualBox" <<< $host; then
    # VBoxGuestAdditions
    clear
    while true; do
        read -e -p "${BLD}${CBL}¿Quieres instalar las Guest Additions de VBox? [s/N]:${CNC} " vbox
        clear

        case $vbox in
            [Ss]*)
                logo "Instalando Guest Additions..."
                sleep 3
                arch-chroot /mnt /bin/bash -c "pacman -Sy virtualbox-guest-iso --noconfirm"
                arch-chroot /mnt /bin/bash -c "mkdir /VBox"
                arch-chroot /mnt /bin/bash -c "mount /usr/lib/virtualbox/additions/VBoxGuestAdditions.iso /VBox"
                arch-chroot /mnt /bin/bash -c "chmod +x /Vbox/VBoxLinuxAdditions.run"
                arch-chroot /mnt /bin/bash -c "(echo yes) | sh /Vbox/VBoxLinuxAdditions.run"
                arch-chroot /mnt /bin/bash -c "rm -rf /VBox"
                break
            ;;
            [Nn]*) break;;
            *) printf "%s%sError: Escribe solo 's' o 'n'%s\n\n" "${BLD}" "${CRE}" "${CNC}";;
        esac
    done
else
    continue
fi

# Servicios
arch-chroot /mnt /bin/bash -c "systemctl enable NetworkManager"
arch-chroot /mnt /bin/bash -c "systemctl enable wpa_supplicant"
clear

# Chroot
while true; do
    read -e -p "${BLD}${CBL}¿Quieres realizar alguna configuración más en chroot? [s/N]:${CNC} " chroot
    clear
    case $chroot in
        [Ss]*) arch-chroot /mnt;;
        [Nn]*) break;;
        *) printf "\n%s%sError: Escribe solo 's' o 'n'%s" "${BLD}" "${CRE}" "${CNC}";;
    esac
done

# Reinicio del sistema
clear
logo "Reiniciando el sistema..."
sleep 5
reboot now