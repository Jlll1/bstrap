su

#TODO create paritions

mount /dev/disk/by-label/ROOT /mnt
mkdir /mnt/boot
mount /dev/disk/by-label/BOOT /mnt/boot
mkdir /mnt/home
mount /dev/disk/by-label/HOME /mnt/home

#TODO setup wireless

sv up ntpd
basestrap /mnt base base-devel runit elogind-runit
basestrap /mnt linux linux-firmware

fstabgen -U /mnt >> /mnt/etc/fstab
artix-chroot /mnt

ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
hwclock --systohc

pacman -S grub os-prober efibootmgr

passwd
useradd -m rb
passwd rb

printf "\n127.0.0.1\tlocalhost\n::1\tlocalhost\n" >> /etc/hosts

pacman -S dhcpcd wpa_supplicant connman-runit connman-gtk
ln -s /etc/runit/sv/connmand /etc/runit/runsvdir/default

pacman -S xorg-server xf86-video-amdgpu xorg-xinit

exit
umount -R /mnt
reboot

