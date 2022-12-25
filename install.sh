USER_NAME="rb"

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

pacman -Syy

pkg_install() {
  if [ -z $(grep "$1" .installed) ]; then
    source "packages/${1}/install"
    echo "$1" >> .installed
  fi
}

install() {
  pacman -S --needed --noconfirm "$@"
}

require() {
  for pkg in "$@"; do
    if [ -z $(ls packages | grep $pkg) ]; then
      pkg_install $pkg
    else
      install $pkg
    fi
  done
}

envvar() {
  echo "$@" >> /home/${USER_NAME}/.bashrc
}

require pacman firefox keepasxc transmission-gtk neovim xorg-server xf86-video-amdgpu xorg-xinit pulseaudio \
  pavucontrol alacritty connman dmenu dmenu_mount dotnet dunst dwm dwm_brightness dwm_volume git mpv \
  xfce-polkit bash

