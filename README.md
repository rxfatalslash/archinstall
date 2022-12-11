Este es un script automatizado para la instalación de Arch Linux, existen una amplia gama de opciones a elegir en la instalación del sistema

# Instalación
Primero se inicia el sistema desde la imagen ISO de Arch Linux y una vez se entre en el sistema se debe cargar la configuración de teclado correspondiente a nuestra zona con el comando **loadkeys _zona_**, después instalamos git para poder clonar el repositorio
```
loadkeys es
pacman -Sy git --noconfirm
```
## Clonado de repositorio
```
git clone https://github.com/rxfatalslash/archinstall
cd archinstall/
./archinstall.sh
```
