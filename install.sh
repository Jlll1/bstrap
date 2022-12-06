mkfs.fat -F 32 /dev/nvme0n1p1
fatlabel /dev/nvme0n1p1 BOOT
mkfs.ext4 -L ROOT /dev/nvme0n1p2

mount /dev/nvme0n1p2 /mnt
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

#TODO setup wireless

basestrap /mnt base base-devel runit elogind-runit
basestrap /mnt linux linux-firmware

fstabgen -U /mnt >> /mnt/etc/fstab
artix-chroot /mnt

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

printf "\n127.0.0.1\tlocalhost\n::1\t\tlocalhost\n" >> /etc/hosts

pacman -S dhcpcd wpa_supplicant connman-runit connman-gtk
ln -s /etc/runit/sv/connmand /etc/runit/runsvdir/default

# Base pkgs
pacman -S firefox keepassxc transmission-gtk neovim


#### Set up git/github key
echo 'Setting up git/github key'
pacman -Sy --needed openssh git
git config --global user.email "arghantentua@tutanota.com"
git config --global user.name "Jlll1"

ssh-keygen -t ed25519 -C "arghantentua@tutanota.com" -N $GH_SSH_PASSPHRASE -f /home/rb/.ssh/gh

##### Set up xorg
echo 'Setting up xorg'
pacman -Sy --needed xorg-server xf86-video-amdgpu xorg-xinit

#### Set up suckless suite
echo 'Setting up suckless suite'
pacman -Sy --needed git

git clone https://github.com/Jlll1/dwm
cd dwm && make install && cd .. && rm -rf dwm

git clone https://git.suckless.org/dmenu
cd dmenu && make install && cd .. && rm -rf dmenu

git clone https://git.suckless.org/st
cd st && make install && cd .. && rm -rf st

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
printf '\n[universe]\n' >> /etc/pacman.conf
printf '\nServer = https://universe.artixlinux.org/$arch' >> /etc/pacman.conf
printf '\nServer = https://mirror1.artixlinux.org/universe/$arch' >> /etc/pacman.conf
printf '\nServer = https://mirror.pascalpuffke.de/artix-universe/$arch' >> /etc/pacman.conf
printf '\nServer = https://artixlinux.qontinuum.space/artixlinux/universe/os/$arch' >> /etc/pacman.conf
printf '\nServer = https://mirror1.cl.netactuate.com/artix/universe/$arch' >> /etc/pacman.conf
printf '\nServer = https://ftp.crifo.org/artix-universe/\n' >> /etc/pacman.conf

pacman -Sy artix-archlinux-support

printf '[extra]\n' >> /etc/pacman.conf
printf 'Include = /etc/pacman.d/mirrorlist-arch\n' >> /etc/pacman.conf
printf '\n[community]\n' >> /etc/pacman.conf
printf 'Include = /etc/pacman.d/mirrorlist-arch\n' >> /etc/pacman.conf
printf '\n[multilib]\n' >> /etc/pacman.conf
printf 'Include = /etc/pacman.d/mirrorlist-arch\n' >> /etc/pacman.conf

#### Setup backlight controls
echo 'Setting up backlight controls'
pacman -Sy acpid-runit
ln -s /etc/runit/sv/acpid /run/runit/service
sv up acpid
usermod -aG video rb
chgrp video /sys/class/backlight/amdgpu_b10/brightness

printf '#!/bin/sh\ncb=$(cat /sys/class/backlight/amdgpu_bl0/brightness)\necho $(($cb + 20)) > /sys/class/backlight/amdgpu_bl0/brightness\n' > /usr/local/bin/brightness_up
chmod +x /usr/local/bin/brightness_up
printf '#1/bin/sh\ncb=$(cat /sys/class/backlight/amdgpu_bl0/brightness\necho $(($cb - 20)) > /sys/class/backlight/amdgpu_bl0/brightness\n' > /usr/local/bin/brightness_down
chmod +x /usr/local/bin/brightness_down
