#TODO create paritions

mount /dev/disk/by-label/ROOT /mnt
mkdir /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot
mkdir /mnt/home
mount /dev/disk/by-label/HOME /mnt/home

#TODO setup wireless

basestrap /mnt base base-devel runit elogind-runit
basestrap /mnt linux linux-firmware

fstabgen -U /mnt >> /mnt/etc/fstab
artix-chroot /mnt

ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
hwclock --systohc

pacman -S grub os-prober efibootmgr
grub-install --target=x86_64_efi --efi-directory=/boot --bootloader-id=grub
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


