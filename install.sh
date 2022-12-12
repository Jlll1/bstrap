ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
hwclock --systohc

pacman -S grub os-prober efibootmgr
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg

echo 'Root password: '
passwd
useradd -m rb
echo 'User password: '
passwd rb

cat << EOT >> /etc/hosts
127.0.0.1	localhost
::1		localhost
EOT

pacman -S dhcpcd wpa_supplicant connman-runit connman-gtk
ln -s /etc/runit/sv/connmand /etc/runit/runsvdir/default

# Base pkgs
pacman -S firefox keepassxc transmission-gtk neovim


#### Set up git/github key
echo 'Setting up git/github key'
pacman -Sy --needed openssh git

cat << EOT > /home/rb/.gitconfig
[user]
	email = "arghantentua@tutanota.com"
	name = "Jlll1"
EOT

PASSPHRASE=${GH_SSH_PASSPHRASE:''}
ssh-keygen -t ed25519 -C "arghantentua@tutanota.com" -N $PASSPHRASE -f /home/rb/.ssh/gh

##### Set up xorg
echo 'Setting up xorg'
pacman -Sy --needed xorg-server xf86-video-amdgpu xorg-xinit

#### Set up suckless suite
echo 'Setting up suckless suite'
pacman -Sy --needed git ttf-font-awesome xorg-xsetroot
pacman -S --needed imlib2 #needed for icons in dwm

git clone https://github.com/Jlll1/dwm
cd dwm && make install && cd .. && rm -rf dwm

git clone https://git.suckless.org/dmenu
cd dmenu && make install && cd .. && rm -rf dmenu

echo 'exec dwm' > /home/rb/.xinitrc

#### Set up polkit
echo 'Setting up polkit'
pacman -Sy --needed git base-devel
git clone https://aur.archlinux.org/xfce-polkit.git
cd xfce-polkit && makepkg -si && cd .. && rm -rf xfce-polkit
sed -i '1 i\exec --no-startup-id /usr/lib/xfce-polkit/xfce-polkit &' /home/rb/.xinitrc

#### Install udisks
pacman -Sy --needed udisks2

#### Setup arch repos

cat << EOT >> /etc/pacman.conf

[universe]
Server = https://universe.artixlinux.org/$arch
Server = https://mirror1.artixlinux.org/universe/$arch
Server = https://mirror.pascalpuffke.de/artix-universe/$arch
Server = https://artixlinux.qontinuum.space/artixlinux/universe/os/$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/$arch
Server = https://ftp.crifo.org/artix-universe/

EOT

pacman -Sy artix-archlinux-support

cat << EOT >> /etc/pacman.conf
[extra]
Include = /etc/pacman.d/mirrorlist-arch

[community]\n' >> /etc/pacman.conf
Include = /etc/pacman.d/mirrorlist-arch

[multilib]\n' >> /etc/pacman.conf
Include = /etc/pacman.d/mirrorlist-arch

EOT

#### Setup backlight controls
echo 'Setting up backlight controls'
pacman -Sy acpid acpid-runit
ln -s /etc/runit/sv/acpid /run/runit/service
sv up acpid
usermod -aG video rb
chgrp video /sys/class/backlight/amdgpu_b10/brightness

cat << EOT > /usr/local/bin/brightness_up
#!/bin/sh

cb=$(cat /sys/class/backlight/amdgpu_bl0/brightness)
echo $(($cb + 20)) > /sys/class/backlight/amdgpu_bl0/brightness

EOT
chmod +x /usr/local/bin/brightness_up

cat << EOT > /usr/local/bin/brightness_up
#!/bin/sh

cb=$(cat /sys/class/backlight/amdgpu_bl0/brightness
echo $(($cb - 20)) > /sys/class/backlight/amdgpu_bl0/brightness

EOT
chmod +x /usr/local/bin/brightness_down

#### Install alacritty
pacman -S --needed alacritty

#### Set up pavucontrol
pacman -S --needed pulseuadio pavucontrol

#### Set up mpv
pacman -S --needed mpv

# mpv-autosub
pacman -S --needed python python-pip
pip install setuptools subliminal

git clone https://github.com/davidde/mpv-autosub
mkdir -p /home/rb/.config/mpv/scripts
cp mpv-autosub/autosub.lua /home/rb/.config/mpv/scripts/
rm -r mpv-autosub

# autosubsync-mpv
pacman -S --needed ffmpeg
pip install ffsubsync
git clone https://github.com/Ajatt-Tools/autosubsync-mpv /home/rb/.config/mpv/scripts/autosubsync


