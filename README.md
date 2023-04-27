Este es un script automatizado para la instalación de Arch Linux, existe una amplia gama de opciones a elegir en la instalación del sistema

# Instalación
Primero se inicia el sistema desde la imagen ISO de Arch Linux y una vez se entre en el sistema se debe cargar la configuración de teclado correspondiente a nuestra zona con el comando **loadkeys _zona_**, después instalamos git para poder clonar el repositorio
```
loadkeys es
pacman -Syy
pacman -Sy archlinux-keyring --noconfirm
```
Si obtienes un error PGP signature ejecuta los siguientes comandos
```
pacman-key --init
pacman-key --populate archlinux
```
Si el problema persiste, reinicia el sistema y vuelve a intentar instalar los paquetes necesarios
<br><br>
Instala git
```
pacman -Sy git --noconfirm
```
## Clonado de repositorio
Clonamos el repositorio, entramos en él y ejecutamos el instalador. Aquí empezará todo el proceso de instalación del sistema Arch Linux
```
git clone https://github.com/rxfatalslash/archinstall
cd archinstall/
sh archinstall.sh
```
